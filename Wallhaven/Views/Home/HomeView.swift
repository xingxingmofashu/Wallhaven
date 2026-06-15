import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var selectedWallpaper: Wallpaper?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Wallhaven")
                .toolbar { toolbarItems }
                .task { viewModel.loadInitial() }
                .refreshable { viewModel.refresh() }
                .navigationDestination(item: $selectedWallpaper) { wallpaper in
                    WallpaperDetailView(wallpaper: wallpaper)
                }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            loadingView

        case .loaded:
            WallpaperGrid(
                wallpapers: viewModel.wallpapers,
                isLoadingMore: viewModel.isLoadingMore,
                onLoadMore: { viewModel.loadMore() },
                onSelect: { selectedWallpaper = $0 }
            )

        case .failed(let error):
            ErrorView(message: error.errorDescription ?? "Unknown error") {
                viewModel.refresh()
            }
        }
    }

    private var loadingView: some View {
        ProgressView("Loading…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                viewModel.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
    }
}

#Preview {
    HomeView()
}
