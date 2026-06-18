import UIKit

/// NSCache-based in-memory image cache (thread-safe)
final class CacheImage: @unchecked Sendable {
    static let shared = CacheImage()

    private let imageCache = NSCache<NSString, UIImage>()
    private let dataCache  = NSCache<NSString, NSData>()
    private let lock  = NSLock()

    private init() {
        imageCache.countLimit     = 200
        imageCache.totalCostLimit = 1024 * 1024 * 150  // 150 MB
        dataCache.countLimit      = 100
        dataCache.totalCostLimit  = 1024 * 1024 * 150
    }

    func image(for url: URL) -> UIImage? {
        lock.lock(); defer { lock.unlock() }
        return imageCache.object(forKey: url.absoluteString as NSString)
    }

    func data(for url: URL) -> Data? {
        lock.lock(); defer { lock.unlock() }
        return dataCache.object(forKey: url.absoluteString as NSString) as Data?
    }

    func insert(_ image: UIImage, for url: URL) {
        lock.lock(); defer { lock.unlock() }
        let cost = image.jpegData(compressionQuality: 1)?.count ?? 0
        imageCache.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
    }

    func insert(data: Data, for url: URL) {
        lock.lock(); defer { lock.unlock() }
        dataCache.setObject(data as NSData, forKey: url.absoluteString as NSString, cost: data.count)
    }

    func removeAll() {
        lock.lock(); defer { lock.unlock() }
        imageCache.removeAllObjects()
        dataCache.removeAllObjects()
    }

    func preload(url: URL) {
        guard image(for: url) == nil else { return }
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled, let loaded = UIImage(data: data) else { return }
                self.insert(loaded, for: url)
                self.insert(data: data, for: url)
            } catch {}
        }
    }
}
