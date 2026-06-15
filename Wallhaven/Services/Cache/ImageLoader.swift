import SwiftUI

@Observable
final class CacheImageLoader {
    var image: UIImage?
    var isLoading = false
    var failed    = false

    private var currentURL: URL?
    private var task: Task<Void, Never>?

    func load(url: URL?) {
        guard let url, url != currentURL else { return }
        cancel()
        currentURL = url

        if let cached = CacheImage.shared.image(for: url) {
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
                    CacheImage.shared.insert(img, for: url)
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
