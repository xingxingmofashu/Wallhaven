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

    // MARK: - Wallhaven Username

    var wallhavenUsername: String {
        get { UserDefaults.standard.string(forKey: "wallhaven_username") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "wallhaven_username") }
    }

    // MARK: - User Settings (from API)

    var userSettings: UserSettings?
    var isLoadingSettings = false
    var settingsError: Error?

    func fetchUserSettings() async {
        guard hasApiKey else {
            userSettings = nil
            return
        }
        isLoadingSettings = true
        settingsError = nil
        do {
            userSettings = try await WallhavenFetch.shared.userSettings()
        } catch {
            settingsError = error
        }
        isLoadingSettings = false
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
