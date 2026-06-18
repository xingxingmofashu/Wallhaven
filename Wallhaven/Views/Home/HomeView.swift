import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var selectedWallpaper: Wallpaper?

    var body: some View {
        NavigationStack {
            HomeContentView(
                loadState: viewModel.loadState,
                wallpapers: viewModel.wallpapers,
                isLoadingMore: viewModel.isLoadingMore,
                onLoadMore: { viewModel.loadMore() },
                onRefresh: { viewModel.refresh() },
                onSelect: { selectedWallpaper = $0 }
            )
            .navigationTitle("Wallhaven")
            .task { viewModel.loadInitial() }
            .refreshable { viewModel.refresh() }
            .navigationDestination(item: $selectedWallpaper) { wallpaper in
                if let index = viewModel.wallpapers.firstIndex(where: { $0.id == wallpaper.id }),
                   viewModel.wallpapers.indices.contains(index)
                {
                    DetailView(
                        wallpapers: viewModel.wallpapers,
                        startIndex: index
                    )
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
