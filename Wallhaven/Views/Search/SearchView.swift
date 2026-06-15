import SwiftUI

struct SearchView: View {
    @State private var viewModel        = SearchViewModel()
    @State private var selectedWallpaper: Wallpaper?
    @State private var showFilter       = false

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadState {
                case .idle:
                    idleView

                case .loading:
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .loaded:
                    if viewModel.wallpapers.isEmpty {
                        EmptyResultView()
                    } else {
                        resultsView
                    }

                case .failed(let error):
                    ErrorView(message: (error as? LocalizedError)?.errorDescription ?? "Unknown error") {
                        viewModel.search()
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(
                text: $viewModel.filters.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search wallpapers, tags..."
            )
            .onSubmit(of: .search) {
                viewModel.search()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFilter = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showFilter) {
                FilterSheet(filters: $viewModel.filters) {
                    viewModel.search()
                }
            }
            .navigationDestination(item: $selectedWallpaper) { wallpaper in
                WallpaperDetailView(wallpaper: wallpaper)
            }
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        ContentUnavailableView(
            "Search Wallpapers",
            systemImage: "magnifyingglass",
            description: Text("Enter keywords to search, or tap the filter button to set conditions")
        )
    }

    // MARK: - Results

    private var resultsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Result count
            Text("\(viewModel.totalResults) results")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 4)

            WallpaperGrid(
                wallpapers: viewModel.wallpapers,
                isLoadingMore: viewModel.isLoadingMore,
                onLoadMore: { viewModel.loadMore() },
                onSelect: { selectedWallpaper = $0 }
            )
        }
    }
}

#Preview {
    SearchView()
}
