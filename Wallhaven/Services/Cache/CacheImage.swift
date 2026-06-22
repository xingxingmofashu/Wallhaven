import UIKit

/// Two-level image cache: in-memory (NSCache) + disk (Caches/WallhavenImages/).
/// Thread-safe via `cacheLock`.
final class CacheImage: @unchecked Sendable {
    static let shared = CacheImage()

    private let imageCache = NSCache<NSString, UIImage>()
    private let dataCache  = NSCache<NSString, NSData>()
    private let cacheLock  = NSLock()

    private let diskCacheURL: URL
    private let diskQueue = DispatchQueue(label: "com.wallhaven.diskcache", qos: .utility)
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
        let cost = image.jpegData(compressionQuality: 1)?.count ?? 0
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

    func removeDisk(for url: URL) {
        try? FileManager.default.removeItem(at: diskFileURL(for: url))
    }

    // MARK: - Combined load

    func cachedImage(for url: URL) -> UIImage? {
        if let mem = image(for: url) { return mem }
        if let disk = diskData(for: url) {
            insertDisk(data: disk, for: url)
            if let img = UIImage(data: disk) {
                insert(img, for: url)
                insert(data: disk, for: url)
                return img
            }
        }
        return nil
    }

    func cachedData(for url: URL) -> Data? {
        if let mem = data(for: url) { return mem }
        return diskData(for: url)
    }

    func load(url: URL) async -> UIImage? {
        if let mem = image(for: url) { return mem }

        return await withCheckedContinuation { continuation in
            diskQueue.async { [weak self] in
                guard let self else { continuation.resume(returning: nil); return }
                if let diskData = self.diskData(for: url) {
                    if let img = UIImage(data: diskData) {
                        self.insert(img, for: url)
                        self.insert(data: diskData, for: url)
                        continuation.resume(returning: img)
                    } else {
                        continuation.resume(returning: nil)
                    }
                    return
                }
                Task {
                    let result = await self.download(url: url)
                    continuation.resume(returning: result)
                }
            }
        }
    }

    func download(url: URL) async -> UIImage? {
        if let mem = image(for: url) { return mem }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            insertDisk(data: data, for: url)
            insert(data: data, for: url)
            guard !Task.isCancelled, let loaded = UIImage(data: data) else { return nil }
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
