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
    private var searchTask: Task<Void, Never>?

    private func applyWebsiteDefaults() {
        guard !didApplyDefaults, let settings = UserSettingsStore.shared.settings else { return }
        filters.applyWebsiteDefaults(from: settings)
        didApplyDefaults = true
    }

    // MARK: - Load

    func loadInitial() {
        guard case .idle = loadState else { return }
        applyWebsiteDefaults()
        searchTask?.cancel()
        searchTask = Task { await fetchFirstPage() }
    }

    func refresh() async {
        searchTask?.cancel()
        searchTask = Task {
            guard case .loaded = loadState else {
                await fetchFirstPage()
                return
            }
            let oldIDs = Set(wallpapers.map(\.id))
            currentPage = 1
            do {
                let response = try await FetchActor.shared.search(filters: filters, page: 1)
                let newIDs = Set(response.data.map(\.id))
                if oldIDs != newIDs {
                    wallpapers = response.data
                }
                hasNextPage = response.meta.hasNextPage
                currentPage = response.meta.currentPage
                loadState = .loaded
            } catch {
                loadState = .loaded
            }
        }
        _ = await searchTask?.result
    }

    func loadMore() {
        guard !isLoadingMore, hasNextPage else { return }
        searchTask?.cancel()
        searchTask = Task { await fetchNextPage() }
    }

    // MARK: - Private

    private func fetchFirstPage() async {
        loadState   = .loading
        currentPage = 1
        wallpapers  = []

        do {
            let response = try await FetchActor.shared.search(filters: filters, page: 1)
            wallpapers   = response.data
            hasNextPage  = response.meta.hasNextPage
            currentPage  = response.meta.currentPage
            loadState    = .loaded
        } catch let error as FetchError {
            loadState = .failed(error)
        } catch {
            loadState = .failed(FetchError.networkError(error.localizedDescription))
        }
    }

    private func fetchNextPage() async {
        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = currentPage + 1
        do {
            let response = try await FetchActor.shared.search(filters: filters, page: nextPage)
            wallpapers  += response.data
            hasNextPage  = response.meta.hasNextPage
            currentPage  = response.meta.currentPage
        } catch {
            // Silently handle load-more failures without overwriting main state
        }
    }
}
