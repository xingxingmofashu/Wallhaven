import Foundation

@Observable
@MainActor
final class SearchViewModel {

    // MARK: - State

    var wallpapers: [Wallpaper] = []
    var loadState: LoadState    = .idle
    var isLoadingMore           = false
    var hasNextPage             = false
    var totalResults            = 0

    // Search query & filter criteria
    var filters: SearchFilters  = SearchFilters()

    private var currentPage       = 0
    private var searchTask: Task<Void, Never>?

    // MARK: - Search

    /// Trigger search with new query/filters (resets pagination)
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

            // Save seed for random sorting, reuse on pagination to avoid duplicates
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
