import SwiftUI

struct HomeContentView: View {
    let loadState: LoadState
    let wallpapers: [Wallpaper]
    let isLoadingMore: Bool
    let onLoadMore: () -> Void
    let onRefresh: () -> Void
    let onSelect: (Wallpaper) -> Void

    var body: some View {
        switch loadState {
        case .idle, .loading:
            LoadingView()

        case .loaded:
            GridView(
                wallpapers: wallpapers,
                isLoadingMore: isLoadingMore,
                onLoadMore: onLoadMore,
                onSelect: onSelect
            )

        case .failed(let error):
            ErrorView(message: (error as? LocalizedError)?.errorDescription ?? "Unknown error", retryAction: onRefresh)
        }
    }
}
