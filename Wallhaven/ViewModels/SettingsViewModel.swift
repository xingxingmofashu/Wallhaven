import Foundation

@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - API Key

    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "wallhaven_api_key") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "wallhaven_api_key") }
    }

    var hasApiKey: Bool { !apiKey.isEmpty }

    // MARK: - API Base URL

    var apiBaseURL: String {
        get { UserDefaults.standard.string(forKey: "wallhaven_api_base_url") ?? "https://wallhaven.cc/api/v1" }
        set { UserDefaults.standard.set(newValue, forKey: "wallhaven_api_base_url") }
    }

    // MARK: - User Settings (from API)

    var userSettings: UserSettings? { UserSettingsStore.shared.settings }
    var isLoadingSettings: Bool     { UserSettingsStore.shared.isLoading }

    func fetchUserSettings() async {
        await UserSettingsStore.shared.load()
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
