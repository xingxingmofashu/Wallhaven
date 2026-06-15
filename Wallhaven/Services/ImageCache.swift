import SwiftUI

/// NSCache-based in-memory image cache (thread-safe)
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

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
}
