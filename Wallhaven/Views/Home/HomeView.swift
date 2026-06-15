import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var selectedWallpaper: Wallpaper?
    @State private var showDetail = false

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
            ErrorView(message: error.errorDescription ?? "未知错误") {
                viewModel.refresh()
            }
        }
    }

    private var loadingView: some View {
        ProgressView("加载中…")
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
