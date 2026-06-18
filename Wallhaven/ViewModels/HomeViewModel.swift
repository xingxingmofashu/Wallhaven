import Foundation

@Observable
@MainActor
final class HomeViewModel {

    // MARK: - State

    var wallpapers: [Wallpaper] = []
    var loadState: LoadState    = .idle
    var isLoadingMore           = false
    var hasNextPage             = false

    private var currentPage     = 1

    private var filters = SearchFilters()
    private var didApplyDefaults = false

    private func applyWebsiteDefaults() {
        guard !didApplyDefaults, let settings = UserSettingsStore.shared.settings else { return }
        filters.applyWebsiteDefaults(from: settings)
        didApplyDefaults = true
    }

    // MARK: - Load

    func loadInitial() {
        guard case .idle = loadState else { return }
        applyWebsiteDefaults()
        Task { await fetchFirstPage() }
    }

    func refresh() {
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
            let response = try await WallhavenFetch.shared.search(filters: filters, page: 1)
            wallpapers   = response.data
            hasNextPage  = response.meta.hasNextPage
            currentPage  = response.meta.currentPage
            loadState    = .loaded
        } catch let error as WallhavenError {
            loadState = .failed(error)
        } catch {
            loadState = .failed(WallhavenError.networkError(error))
        }
    }

    private func fetchNextPage() async {
        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = currentPage + 1
        do {
            let response = try await WallhavenFetch.shared.search(filters: filters, page: nextPage)
            wallpapers  += response.data
            hasNextPage  = response.meta.hasNextPage
            currentPage  = response.meta.currentPage
        } catch {
            // Silently handle load-more failures without overwriting main state
        }
    }
}
