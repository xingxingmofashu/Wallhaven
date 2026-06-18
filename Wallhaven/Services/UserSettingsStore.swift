import Foundation

@Observable
@MainActor
final class UserSettingsStore {
    static let shared = UserSettingsStore()
    private(set) var settings: UserSettings?
    private(set) var isLoading = false

    private init() {}

    func load() async {
        let key = UserDefaults.standard.string(forKey: "wallhaven_api_key")
        guard let key, !key.isEmpty else {
            settings = nil
            return
        }
        isLoading = true
        do {
            settings = try await WallhavenFetch.shared.userSettings()
        } catch {
            // keep previous value on failure
        }
        isLoading = false
    }
}
