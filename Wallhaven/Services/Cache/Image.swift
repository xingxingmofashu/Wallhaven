import SwiftUI

/// NSCache-based in-memory image cache (thread-safe)
final class CacheImage: @unchecked Sendable {
    static let shared = CacheImage()

    private let cache = NSCache<NSString, UIImage>()
    private let lock  = NSLock()

    private init() {
        cache.countLimit     = 200
        cache.totalCostLimit = 1024 * 1024 * 150  // 150 MB
    }

    func image(for url: URL) -> UIImage? {
        lock.lock(); defer { lock.unlock() }
        return cache.object(forKey: url.absoluteString as NSString)
    }

    func insert(_ image: UIImage, for url: URL) {
        lock.lock(); defer { lock.unlock() }
        let cost = image.jpegData(compressionQuality: 1)?.count ?? 0
        cache.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
    }

    func removeAll() {
        lock.lock(); defer { lock.unlock() }
        cache.removeAllObjects()
    }

    func preload(url: URL) {
        guard image(for: url) == nil else { return }
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled, let loaded = UIImage(data: data) else { return }
                self.insert(loaded, for: url)
            } catch {}
        }
    }
}
