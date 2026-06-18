import Foundation

@Observable
@MainActor
final class CollectionsViewModel {

    var collections: [WHCollection] = []
    var isLoading = false
    var error: Error?

    var username: String {
        UserDefaults.standard.string(forKey: "wallhaven_username") ?? ""
    }

    var hasUsername: Bool { !username.isEmpty }

    func loadCollections() async {
        isLoading = true
        error = nil
        do {
            collections = try await WallhavenFetch.shared.collections()
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
