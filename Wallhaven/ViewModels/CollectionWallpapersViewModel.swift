import Observation

@Observable
@MainActor
final class CollectionWallpapersViewModel {
    let collection: WHCollection
    let username: String

    var wallpapers: [Wallpaper] = []
    var isLoading = false
    var isLoadingMore = false
    var hasMore = true
    var error: Error?

    private var currentPage = 1

    init(collection: WHCollection, username: String) {
        self.collection = collection
        self.username = username
    }

    func loadFirstPage() async {
        isLoading = true
        error = nil
        currentPage = 1
        hasMore = true
        do {
            let response = try await WallhavenFetch.shared.collectionWallpapers(
                username: username,
                collectionId: collection.id,
                page: 1
            )
            wallpapers = response.data
            hasMore = response.meta.hasNextPage
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func loadMore() async {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        let nextPage = currentPage + 1
        do {
            let response = try await WallhavenFetch.shared.collectionWallpapers(
                username: username,
                collectionId: collection.id,
                page: nextPage
            )
            wallpapers += response.data
            hasMore = response.meta.hasNextPage
            currentPage = nextPage
        } catch {
            // silently fail pagination
        }
        isLoadingMore = false
    }
}
