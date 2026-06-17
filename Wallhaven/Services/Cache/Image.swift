import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

/// NSCache-based in-memory image cache (thread-safe)
final class CacheImage: @unchecked Sendable {
    static let shared = CacheImage()

    private let cache = NSCache<NSString, PlatformImage>()
    private let lock  = NSLock()

    private init() {
        cache.countLimit     = 200
        cache.totalCostLimit = 1024 * 1024 * 150  // 150 MB
    }

    func image(for url: URL) -> PlatformImage? {
        lock.lock(); defer { lock.unlock() }
        return cache.object(forKey: url.absoluteString as NSString)
    }

    func insert(_ image: PlatformImage, for url: URL) {
        lock.lock(); defer { lock.unlock() }
        let cost: Int
        #if os(iOS)
        cost = image.jpegData(compressionQuality: 1)?.count ?? 0
        #elseif os(macOS)
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let jpegData = bitmap.representation(using: .jpeg, properties: [:]) {
            cost = jpegData.count
        } else {
            cost = 0
        }
        #endif
        cache.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
    }

    func removeAll() {
        lock.lock(); defer { lock.unlock() }
        cache.removeAllObjects()
    }
}
