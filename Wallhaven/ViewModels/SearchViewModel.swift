import Foundation

@Observable
@MainActor
final class SearchViewModel: HasSearchFilters {

    // MARK: - State

    var wallpapers: [Wallpaper] = []
    var loadState: LoadState    = .idle
    var isLoadingMore           = false
    var hasNextPage             = false
    var totalResults            = 0

    // Search query & filter criteria
    var filters: SearchFilters  = SearchFilters()

    private var currentPage       = 0
    var didApplyDefaults          = false
    private var searchTask: Task<Void, Never>?
    private var loadMoreTask: Task<Void, Never>?

    // MARK: - Search

    /// Trigger search with new query/filters (resets pagination)
    func search() {
        applyWebsiteDefaults()
        loadMoreTask?.cancel()
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await performSearch(reset: true)
        }
    }

    func loadMore() {
        // Guard on `.loaded` and use a dedicated task so loadMore can't cancel
        // an in-flight first-page fetch.
        guard !isLoadingMore, hasNextPage, case .loaded = loadState else { return }
        loadMoreTask?.cancel()
        loadMoreTask = Task {
            await performSearch(reset: false)
        }
    }

    // MARK: - Private

    private func performSearch(reset: Bool) async {
        if reset {
            loadState    = .loading
            wallpapers   = []
            currentPage  = 0
            totalResults = 0
            hasNextPage  = false
            // Drop any seed carried over from a previous random search so each
            // new search gets a fresh random order instead of reusing the old one.
            filters.seed = nil
        } else {
            isLoadingMore = true
        }

        defer { isLoadingMore = false }

        let page = currentPage + 1

        do {
            let response = try await FetchActor.shared.search(filters: filters, page: page)

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
        } catch let error as FetchError {
            if reset { loadState = .failed(error) }
        } catch {
            if reset { loadState = .failed(FetchError.networkError(error.localizedDescription)) }
        }
    }
}
