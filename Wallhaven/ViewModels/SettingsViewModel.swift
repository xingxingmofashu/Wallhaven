import Foundation

@Observable
@MainActor
final class SettingsViewModel {
    static let shared = SettingsViewModel()

    private init() {}

    // MARK: - API Key

    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "wallhaven_api_key") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "wallhaven_api_key") }
    }

    var hasApiKey: Bool { !apiKey.isEmpty }

    // MARK: - API Base URL

    var apiBaseURL: String {
        get { UserDefaults.standard.string(forKey: "wallhaven_api_base_url") ?? FetchActor.defaultBaseURL }
        set { UserDefaults.standard.set(newValue, forKey: "wallhaven_api_base_url") }
    }

    // MARK: - User Settings (from API)

    private(set) var settings: UserSettings?
    private(set) var isLoading = false

    func load() async {
        guard let key = UserDefaults.standard.string(forKey: "wallhaven_api_key"),
              !key.isEmpty else {
            settings = nil
            return
        }
        isLoading = true
        do {
            settings = try await FetchActor.shared.getUserSettings()
        } catch {}
        isLoading = false
    }

    // MARK: - Cache

    func clearImageCache() {
        CacheImage.shared.removeAll()
    }

    // MARK: - App Info

    var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
    }

    var buildNumber: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "1"
    }
}
