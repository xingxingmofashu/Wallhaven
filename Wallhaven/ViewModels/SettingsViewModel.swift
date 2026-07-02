import Foundation

@Observable
@MainActor
final class SettingsViewModel {
    static let shared = SettingsViewModel()

    private init() {
        // Mirror persisted values into @Observable stored properties so SwiftUI
        // can observe changes. UserDefaults-backed *computed* properties alone
        // are not tracked by @Observable, which left the Settings screen stale
        // after saving a key/URL and prevented `load()` from being re-triggered.
        let storedKey = UserDefaults.standard.string(forKey: "wallhaven_api_key")
        _apiKey = storedKey ?? ""

        let storedURL = UserDefaults.standard.string(forKey: "wallhaven_api_base_url")
        _apiBaseURL = (storedURL?.isEmpty ?? true) ? FetchActor.defaultBaseURL : storedURL!
    }

    // MARK: - API Key

    private var _apiKey: String

    var apiKey: String {
        get { _apiKey }
        set {
            _apiKey = newValue
            UserDefaults.standard.set(newValue, forKey: "wallhaven_api_key")
            Task { await FetchActor.shared.refreshConfiguration() }
        }
    }

    var hasApiKey: Bool { !_apiKey.isEmpty }

    // MARK: - API Base URL

    private var _apiBaseURL: String

    var apiBaseURL: String {
        get { _apiBaseURL }
        set {
            let resolved = newValue.isEmpty ? FetchActor.defaultBaseURL : newValue
            _apiBaseURL = resolved
            UserDefaults.standard.set(newValue, forKey: "wallhaven_api_base_url")
            Task { await FetchActor.shared.refreshConfiguration() }
        }
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
