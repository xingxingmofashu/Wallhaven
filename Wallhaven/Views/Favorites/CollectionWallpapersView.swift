import SwiftUI

struct CollectionWallpapersView: View {
    @State private var viewModel: CollectionWallpapersViewModel
    @State private var selectedWallpaper: Wallpaper?

    init(collection: WHCollection, username: String) {
        _viewModel = State(initialValue: CollectionWallpapersViewModel(collection: collection, username: username))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if let error = viewModel.error {
                ErrorView(message: error.localizedDescription) {
                    Task { await viewModel.loadFirstPage() }
                }
            } else if viewModel.wallpapers.isEmpty {
                ContentUnavailableView(
                    "Empty Collection",
                    systemImage: "folder",
                    description: Text("No wallpapers in this collection.")
                )
            } else {
                GridView(
                    wallpapers: viewModel.wallpapers,
                    isLoadingMore: viewModel.isLoadingMore,
                    onLoadMore: { Task { await viewModel.loadMore() } },
                    onSelect: { selectedWallpaper = $0 }
                )
            }
        }
        .navigationTitle(viewModel.collection.label)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadFirstPage() }
        .navigationDestination(item: $selectedWallpaper) { wallpaper in
            if let index = viewModel.wallpapers.firstIndex(where: { $0.id == wallpaper.id }),
               viewModel.wallpapers.indices.contains(index)
            {
                DetailView(wallpapers: viewModel.wallpapers, startIndex: index)
            }
        }
    }
}
