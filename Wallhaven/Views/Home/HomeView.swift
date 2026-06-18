import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var selectedWallpaper: Wallpaper?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Wallhaven")
                .task { viewModel.loadInitial() }
                .refreshable { viewModel.refresh() }
                .navigationDestination(item: $selectedWallpaper) { wallpaper in
                    let index = viewModel.wallpapers.firstIndex(where: { $0.id == wallpaper.id }) ?? 0
                    DetailView(
                        wallpapers: viewModel.wallpapers,
                        startIndex: index
                    )
                }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            LoadingView()

        case .loaded:
            GridView(
                wallpapers: viewModel.wallpapers,
                isLoadingMore: viewModel.isLoadingMore,
                onLoadMore: { viewModel.loadMore() },
                onSelect: { selectedWallpaper = $0 }
            )

        case .failed(let error):
            ErrorView(message: (error as? LocalizedError)?.errorDescription ?? "Unknown error") {
                viewModel.refresh()
            }
        }
    }

}

#Preview {
    HomeView()
}
