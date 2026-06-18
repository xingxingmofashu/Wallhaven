import Foundation

@Observable
@MainActor
final class CollectionsViewModel {

    var collections: [WHCollection] = []
    var isLoading = false
    var error: Error?
    var needsAPIKey = false
    var username = ""

    var hasUsername: Bool { !username.isEmpty }

    init() {
        username = UserDefaults.standard.string(forKey: "wallhaven_username") ?? ""
    }

    func loadCollections() async {
        username = UserDefaults.standard.string(forKey: "wallhaven_username") ?? ""
        isLoading = true
        error = nil
        needsAPIKey = false
        do {
            collections = try await WallhavenFetch.shared.collections()
        } catch WallhavenError.unauthorized {
            needsAPIKey = true
            error = WallhavenError.unauthorized
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
