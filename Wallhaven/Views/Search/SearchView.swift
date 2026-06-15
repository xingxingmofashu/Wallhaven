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
                    ProgressView("搜索中…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .loaded:
                    if viewModel.wallpapers.isEmpty {
                        EmptyResultView()
                    } else {
                        resultsView
                    }

                case .failed(let error):
                    ErrorView(message: error.errorDescription ?? "未知错误") {
                        viewModel.search()
                    }
                }
            }
            .navigationTitle("搜索")
            .searchable(
                text: $viewModel.filters.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "搜索壁纸、标签…"
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
            "搜索壁纸",
            systemImage: "magnifyingglass",
            description: Text("输入关键词开始搜索，或点击筛选按钮设置条件")
        )
    }

    // MARK: - Results

    private var resultsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 结果数量
            Text("共 \(viewModel.totalResults) 张")
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
