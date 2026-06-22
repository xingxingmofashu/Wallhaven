import ImageIO
import UIKit

/// Two-level image cache: in-memory (NSCache) + disk (Caches/WallhavenImages/).
/// Thread-safe via `cacheLock`.
final class CacheImage: @unchecked Sendable {
    static let shared = CacheImage()

    private let imageCache = NSCache<NSString, UIImage>()
    private let dataCache  = NSCache<NSString, NSData>()
    private let cacheLock  = NSLock()

    private let diskCacheURL: URL
    private static let maxDiskFiles = 200

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheURL = caches.appendingPathComponent("WallhavenImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)

        imageCache.countLimit     = 200
        imageCache.totalCostLimit = 1024 * 1024 * 1024  // 1 GB
        dataCache.countLimit      = 100
        dataCache.totalCostLimit  = 1024 * 512 * 1024   // 512 MB
    }

    // MARK: - Memory cache

    func image(for url: URL) -> UIImage? {
        cacheLock.lock(); defer { cacheLock.unlock() }
        return imageCache.object(forKey: url.absoluteString as NSString)
    }

    func data(for url: URL) -> Data? {
        cacheLock.lock(); defer { cacheLock.unlock() }
        return dataCache.object(forKey: url.absoluteString as NSString) as Data?
    }

    func insert(_ image: UIImage, for url: URL) {
        cacheLock.lock(); defer { cacheLock.unlock() }
        // Estimate cost from pixel dimensions (4 bytes per pixel for RGBA).
        // Avoids the expensive jpegData() re-encoding that blocks the main thread.
        let cost = Int(image.size.width * image.scale) * Int(image.size.height * image.scale) * 4
        imageCache.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
    }

    func insert(data: Data, for url: URL) {
        cacheLock.lock(); defer { cacheLock.unlock() }
        dataCache.setObject(data as NSData, forKey: url.absoluteString as NSString, cost: data.count)
    }

    func removeAll() {
        cacheLock.lock(); defer { cacheLock.unlock() }
        imageCache.removeAllObjects()
        dataCache.removeAllObjects()
        try? FileManager.default.removeItem(at: diskCacheURL)
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }

    // MARK: - Disk cache

    func diskData(for url: URL) -> Data? {
        let file = diskFileURL(for: url)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: file.path)
        return try? Data(contentsOf: file)
    }

    func insertDisk(data: Data, for url: URL) {
        let file = diskFileURL(for: url)
        try? data.write(to: file)
        evictDiskIfNeeded()
    }

    // MARK: - Combined load

    func cachedImage(for url: URL) -> UIImage? {
        if let mem = image(for: url) { return mem }
        if let disk = diskData(for: url) {
            if let img = downsampledImage(from: disk) {
                insert(img, for: url)
                insert(data: disk, for: url)
                return img
            }
        }
        return nil
    }

    /// Load image: memory -> disk -> network. Returns a display-sized (downsampled) UIImage.
    func load(url: URL) async -> UIImage? {
        // 1. Memory hit
        if let mem = image(for: url) { return mem }

        // 2. Disk hit (runs file I/O off the caller's context)
        if let diskImage = await loadFromDisk(url: url) {
            return diskImage
        }

        // 3. Network download
        return await download(url: url)
    }

    private func loadFromDisk(url: URL) async -> UIImage? {
        await Task.detached(priority: .utility) { [weak self] () -> UIImage? in
            guard let self, let diskData = self.diskData(for: url) else { return nil }
            guard let img = self.downsampledImage(from: diskData) else { return nil }
            self.insert(img, for: url)
            self.insert(data: diskData, for: url)
            return img
        }.value
    }

    private func download(url: URL) async -> UIImage? {
        if let mem = image(for: url) { return mem }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            insertDisk(data: data, for: url)
            insert(data: data, for: url)
            guard !Task.isCancelled, let loaded = downsampledImage(from: data) else { return nil }
            insert(loaded, for: url)
            return loaded
        } catch {
            return nil
        }
    }

    func preload(url: URL) {
        guard image(for: url) == nil else { return }
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            _ = await self.load(url: url)
        }
    }

    // MARK: - Downsampling

    /// Maximum pixel width for display images. Matches largest iPhone screen width at 3x scale.
    private static let maxDisplayPixelWidth: CGFloat = {
        // UIScreen must be accessed on the main thread.
        if Thread.isMainThread {
            return UIScreen.main.bounds.width * UIScreen.main.scale
        }
        return DispatchQueue.main.sync {
            UIScreen.main.bounds.width * UIScreen.main.scale
        }
    }()

    /// Downsample raw data via ImageIO — decodes only the pixels needed for display.
    /// Falls back to `UIImage(data:)` if ImageIO fails.
    func downsampledImage(from data: Data) -> UIImage? {
        let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
            return UIImage(data: data)
        }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Self.maxDisplayPixelWidth
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Disk helpers

    private func diskFileURL(for url: URL) -> URL {
        let key = url.absoluteString.data(using: .utf8)!.base64EncodedString()
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "+", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return diskCacheURL.appendingPathComponent(key)
    }

    private func evictDiskIfNeeded() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: diskCacheURL, includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return }
        guard files.count > Self.maxDiskFiles else { return }
        let sorted = files.sorted { a, b in
            let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return da < db
        }
        let toRemove = sorted.prefix(files.count - Self.maxDiskFiles)
        for file in toRemove {
            try? FileManager.default.removeItem(at: file)
        }
    }
}
