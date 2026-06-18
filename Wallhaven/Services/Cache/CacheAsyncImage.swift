import SwiftUI

/// CacheAsyncImage with in-memory cache, placeholder and failure states
struct CacheAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let showLoading: Bool
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @State private var loader = CacheImageLoader()

    init(
        url: URL?,
        showLoading: Bool = true,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url         = url
        self.content     = content
        self.placeholder = placeholder
        self.showLoading = showLoading
    }

    var body: some View {
        Group {
            if let uiImage = loader.image {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
                    .overlay {
                        if showLoading {
                            if loader.isLoading {
                                ProgressView()
                            } else if loader.hasFailed {
                                Image(systemName: "photo.badge.exclamationmark")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
            }
        }
        .onAppear { loader.load(url: url) }
        .onChange(of: url) { _, newURL in loader.load(url: newURL) }
        .onDisappear { loader.cancel() }
    }
}
