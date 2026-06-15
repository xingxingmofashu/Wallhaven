import Foundation

@Observable
@MainActor
final class HomeViewModel {

    // MARK: - State

    enum LoadState { case idle, loading, loaded, failed(WallhavenError) }

    var wallpapers: [Wallpaper] = []
    var loadState: LoadState    = .idle
    var isLoadingMore           = false
    var hasNextPage             = false

    private var currentPage     = 1
    private var currentTask: Task<Void, Never>?

    // Home page uses latest SFW as default filter
    private var filters: SearchFilters = {
        var f = SearchFilters()
        f.sorting = .dateAdded
        return f
    }()

    // MARK: - Load

    func loadInitial() {
        guard case .idle = loadState else { return }
        Task { await fetchFirstPage() }
    }

    func refresh() {
        currentTask?.cancel()
        loadState = .idle
        Task { await fetchFirstPage() }
    }

    func loadMore() {
        guard !isLoadingMore, hasNextPage else { return }
        Task { await fetchNextPage() }
    }

    // MARK: - Private

    private func fetchFirstPage() async {
        loadState   = .loading
        currentPage = 1
        wallpapers  = []

        do {
            let response = try await WallhavenAPI.shared.search(filters: filters, page: 1)
            wallpapers   = response.data
            hasNextPage  = response.meta.hasNextPage
            currentPage  = response.meta.currentPage
            loadState    = .loaded
        } catch let error as WallhavenError {
            loadState = .failed(error)
        } catch {
            loadState = .failed(.networkError(error))
        }
    }

    private func fetchNextPage() async {
        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = currentPage + 1
        do {
            let response = try await WallhavenAPI.shared.search(filters: filters, page: nextPage)
            wallpapers  += response.data
            hasNextPage  = response.meta.hasNextPage
            currentPage  = response.meta.currentPage
        } catch {
            // Silently handle load-more failures without overwriting main state
        }
    }
}
