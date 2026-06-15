import SwiftUI

// MARK: - Image Cache

/// 基于 NSCache 的内存图片缓存（线程安全）
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()
    private let lock  = NSLock()

    private init() {
        cache.countLimit     = 200      // 最多缓存 200 张
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

    func remove(for url: URL) {
        lock.lock(); defer { lock.unlock() }
        cache.removeObject(forKey: url.absoluteString as NSString)
    }

    func removeAll() {
        lock.lock(); defer { lock.unlock() }
        cache.removeAllObjects()
    }
}

// MARK: - Cached Async Image ViewModel

@Observable
final class CachedImageLoader {
    var image: UIImage?
    var isLoading = false
    var failed    = false

    private var currentURL: URL?
    private var task: Task<Void, Never>?

    func load(url: URL?) {
        guard let url, url != currentURL else { return }
        cancel()
        currentURL = url

        // 命中缓存
        if let cached = ImageCache.shared.image(for: url) {
            image = cached
            return
        }

        isLoading = true
        failed    = false

        task = Task {
            defer { isLoading = false }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled else { return }
                if let img = UIImage(data: data) {
                    ImageCache.shared.insert(img, for: url)
                    image = img
                } else {
                    failed = true
                }
            } catch {
                guard !Task.isCancelled else { return }
                failed = true
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

// MARK: - CachedAsyncImage View

/// 替代 AsyncImage，带内存缓存，支持占位和失败态
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @State private var loader = CachedImageLoader()

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url         = url
        self.content     = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let uiImage = loader.image {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
                    .overlay {
                        if loader.isLoading {
                            ProgressView()
                        } else if loader.failed {
                            Image(systemName: "photo.badge.exclamationmark")
                                .foregroundStyle(.secondary)
                        }
                    }
            }
        }
        .onAppear { loader.load(url: url) }
        .onChange(of: url) { _, newURL in loader.load(url: newURL) }
        .onDisappear { loader.cancel() }
    }
}
