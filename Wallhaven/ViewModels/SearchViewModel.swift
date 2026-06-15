import Foundation

@Observable
final class SearchViewModel {

    // MARK: - State

    enum LoadState { case idle, loading, loaded, failed(WallhavenError) }

    var wallpapers: [Wallpaper] = []
    var loadState: LoadState    = .idle
    var isLoadingMore           = false
    var hasNextPage             = false
    var totalResults            = 0

    // 搜索词 & 筛选条件
    var filters: SearchFilters  = SearchFilters()

    // 上次实际执行搜索的关键词，避免频繁重复请求
    private var lastSearchedQuery = ""
    private var currentPage       = 0
    private var searchTask: Task<Void, Never>?

    // MARK: - Search

    /// 用新关键词/筛选触发搜索（重置分页）
    func search() {
        searchTask?.cancel()
        searchTask = Task {
            await performSearch(reset: true)
        }
    }

    func loadMore() {
        guard !isLoadingMore, hasNextPage else { return }
        Task { await performSearch(reset: false) }
    }

    func clearResults() {
        wallpapers    = []
        loadState     = .idle
        hasNextPage   = false
        totalResults  = 0
        currentPage   = 0
        filters.query = ""
    }

    // MARK: - Private

    private func performSearch(reset: Bool) async {
        if reset {
            loadState    = .loading
            wallpapers   = []
            currentPage  = 0
            totalResults = 0
            hasNextPage  = false
        } else {
            isLoadingMore = true
        }

        defer { isLoadingMore = false }

        let page = currentPage + 1

        do {
            let response = try await WallhavenAPI.shared.search(filters: filters, page: page)

            // 随机排序时保存 seed，翻页时复用以保证不重复
            if filters.sorting == .random, let seed = response.meta.seed {
                filters.seed = seed
            }

            if reset {
                wallpapers = response.data
            } else {
                wallpapers += response.data
            }

            hasNextPage  = response.meta.hasNextPage
            currentPage  = response.meta.currentPage
            totalResults = response.meta.total
            loadState    = .loaded
        } catch let error as WallhavenError {
            if reset { loadState = .failed(error) }
        } catch {
            if reset { loadState = .failed(.networkError(error)) }
        }
    }
}
