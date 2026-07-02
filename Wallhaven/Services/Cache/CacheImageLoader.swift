import Observation
import UIKit

@Observable
@MainActor
final class CacheImageLoader {
    var image: UIImage?
    var isLoading = false
    var hasFailed = false

    private var currentURL: URL?
    private var task: Task<Void, Never>?

    func load(url: URL?) {
        guard let url, url != currentURL else { return }
        cancel()
        currentURL = url

        // 1. Memory cache hit — instant
        if let cached = CacheImage.shared.image(for: url) {
            isLoading = false
            hasFailed = false
            image = cached
            return
        }

        isLoading = true
        hasFailed = false

        task = Task {
            defer { isLoading = false }

            // 2. Disk cache hit — avoid network round-trip
            if let loaded = await CacheImage.shared.load(url: url) {
                guard !Task.isCancelled else { return }
                image = loaded
                return
            }

            guard !Task.isCancelled else { return }
            hasFailed = true
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        // Reset so a subsequent `load(url:)` for the same URL (e.g. after the
        // view reappears) actually re-evaluates the cache instead of no-oping.
        currentURL = nil
    }
}
