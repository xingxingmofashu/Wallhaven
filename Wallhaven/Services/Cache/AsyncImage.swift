import SwiftUI

/// CacheAsyncImage with in-memory cache, placeholder and failure states
struct CacheAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @State private var loader = CacheImageLoader()

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
            if let platformImage = loader.image {
                #if os(iOS)
                content(Image(uiImage: platformImage))
                #elseif os(macOS)
                content(Image(nsImage: platformImage))
                #endif
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
