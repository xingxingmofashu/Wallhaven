import ImageIO
import UIKit

/// Two-level image cache: in-memory (NSCache) + disk (Caches/WallhavenImages/).
/// Thread-safe via `cacheLock`.
final class CacheImage: @unchecked Sendable {
    static let shared = CacheImage()

    private let imageCache = NSCache<NSString, UIImage>()
    private let dataCache  = NSCache<NSString, NSData>()
    private let cacheLock  = NSLock()

    // Tracks in-flight network downloads by URL for deduplication and cancellation.
    private var activeDownloads: [URL: Task<UIImage?, Never>] = [:]
    private let downloadsLock = NSLock()

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

        // Populate the cached screen width now (init runs on the main thread
        // via first `shared` access) and keep it fresh across rotation/scene
        // changes, so background decoders never need a main-thread hop.
        Self.refreshMaxDisplayPixelWidth()
        let nc = NotificationCenter.default
        nc.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
            Self.refreshMaxDisplayPixelWidth()
        }
        nc.addObserver(forName: UIScene.didActivateNotification, object: nil, queue: .main) { _ in
            Self.refreshMaxDisplayPixelWidth()
        }
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
        // Clear memory caches under the lock, then do the (potentially slow)
        // disk teardown outside it so cache reads aren't blocked by file I/O.
        cacheLock.lock()
        imageCache.removeAllObjects()
        dataCache.removeAllObjects()
        cacheLock.unlock()

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

    /// Load image: memory -> disk -> network. Returns a display-sized (downsampled) UIImage.
    func load(url: URL) async -> UIImage? {
        // 1. Memory hit
        if let mem = image(for: url) { return mem }

        // 2. Disk hit (runs file I/O off the caller's context)
        if let diskImage = await loadFromDisk(url: url) {
            return diskImage
        }

        // 3. Network download — tracked, deduplicated, and cancellable
        return await trackedDownload(url: url)
    }

    /// Start or join an in-flight download for `url`. Deduplicates concurrent
    /// requests for the same URL and allows cancellation via `cancelDownload(for:)`.
    private func trackedDownload(url: URL) async -> UIImage? {
        downloadsLock.lock()
        if let existing = activeDownloads[url] {
            downloadsLock.unlock()
            return await existing.value
        }

        let task = Task.detached(priority: .utility) { [weak self] () -> UIImage? in
            guard let self else { return nil }
            return await self.download(url: url)
        }
        activeDownloads[url] = task
        downloadsLock.unlock()

        let result = await task.value

        downloadsLock.lock()
        activeDownloads.removeValue(forKey: url)
        downloadsLock.unlock()

        return result
    }

    /// Cancel an in-flight network download for the given URL (e.g. when the
    /// view swipes away before the full-res image arrives).
    func cancelDownload(for url: URL) {
        downloadsLock.lock()
        if let task = activeDownloads.removeValue(forKey: url) {
            task.cancel()
        }
        downloadsLock.unlock()
    }

    /// Cancel all in-flight downloads. Called when leaving the detail page.
    func cancelAllDownloads() {
        downloadsLock.lock()
        for (_, task) in activeDownloads {
            task.cancel()
        }
        activeDownloads.removeAll()
        downloadsLock.unlock()
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
            _ = await self.trackedDownload(url: url)
        }
    }

    // MARK: - Downsampling

    /// Maximum pixel width for display images. Cached and refreshed on rotation
    /// / scene activation so background decoders don't hop to the main thread on
    /// every access.
    private static var maxDisplayPixelWidth: CGFloat {
        maxWidthLock.lock(); defer { maxWidthLock.unlock() }
        if cachedMaxDisplayPixelWidth == 0 {
            cachedMaxDisplayPixelWidth = currentScreenMaxPixelWidth()
        }
        return cachedMaxDisplayPixelWidth
    }

    static func refreshMaxDisplayPixelWidth() {
        let width = currentScreenMaxPixelWidth()
        maxWidthLock.lock(); defer { maxWidthLock.unlock() }
        cachedMaxDisplayPixelWidth = width
    }

    private static func currentScreenMaxPixelWidth() -> CGFloat {
        // Resolve the current screen via the window scene (non-deprecated path for iOS 26+).
        let screen: UIScreen? = {
            if Thread.isMainThread {
                return UIApplication.shared
                    .connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?
                    .screen
            }
            return DispatchQueue.main.sync {
                UIApplication.shared
                    .connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?
                    .screen
            }
        }()
        // Sensible fallback when no window scene is available yet.
        return (screen?.bounds.width ?? 430) * (screen?.scale ?? 3)
    }

    // MARK: - Cached screen width

    private static let maxWidthLock = NSLock()
    private static var cachedMaxDisplayPixelWidth: CGFloat = 0

    /// Downsample raw data via ImageIO — decodes only the pixels needed for display.
    /// On ImageIO failure, falls back to a manual downscale so the cache never stores
    /// full-resolution images.
    func downsampledImage(from data: Data) -> UIImage? {
        let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
        if let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary),
           let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Self.maxDisplayPixelWidth
           ] as CFDictionary) {
            return UIImage(cgImage: cgImage)
        }
        // ImageIO path failed — decode full-res then downscale so the image cache
        // never stores a full-resolution entry.
        guard let full = UIImage(data: data) else { return nil }
        let scale = full.scale
        let pixelWidth = full.size.width * scale
        let maxWidth = Self.maxDisplayPixelWidth
        guard pixelWidth > maxWidth else { return full }
        let ratio = maxWidth / pixelWidth
        let target = CGSize(width: full.size.width * ratio, height: full.size.height * ratio)
        return full.preparingThumbnail(of: target)
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
