import SwiftUI

struct SearchView: View {
    @State private var viewModel        = SearchViewModel()
    @State private var selectedWallpaper: Wallpaper?
    @State private var showFilter       = false
    @Environment(NavigationState.self) private var navigationState

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
                        EmptyView()
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
            .onChange(of: navigationState.shouldSearch) { _, should in
                guard should else { return }
                viewModel.filters.query = navigationState.searchQuery
                navigationState.shouldSearch = false
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
                FilterSheetView(filters: $viewModel.filters) {
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

            GridView(
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
