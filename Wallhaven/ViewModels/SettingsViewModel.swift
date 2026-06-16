import Foundation

@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - Language

    enum AppLanguage: String, CaseIterable, Identifiable {
        case system = ""
        case en     = "en"
        case zhHans = "zh-Hans"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .system: return NSLocalizedString("settings.language.follow_system", comment: "")
            case .en:     return NSLocalizedString("settings.language.english", comment: "")
            case .zhHans: return NSLocalizedString("settings.language.chinese", comment: "")
            }
        }
    }

    var selectedLanguage: AppLanguage {
        get {
            let raw = UserDefaults.standard.string(forKey: "AppLanguage") ?? ""
            return AppLanguage(rawValue: raw) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "AppLanguage")
            if newValue == .system {
                Bundle.resetLanguage()
            } else {
                Bundle.setLanguage(newValue.rawValue)
            }
        }
    }

    func applyLanguageOverride() {
        let raw = UserDefaults.standard.string(forKey: "AppLanguage") ?? ""
        let lang = AppLanguage(rawValue: raw) ?? .system
        if lang == .system {
            Bundle.resetLanguage()
        } else {
            Bundle.setLanguage(lang.rawValue)
        }
    }

    // MARK: - API Key

    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "wallhaven_api_key") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "wallhaven_api_key") }
    }

    var hasAPIKey: Bool { !apiKey.isEmpty }

    // MARK: - API Base URL

    var apiBaseURL: String {
        get { UserDefaults.standard.string(forKey: "wallhaven_api_base_url") ?? "https://wallhaven.cc/api/v1" }
        set { UserDefaults.standard.set(newValue, forKey: "wallhaven_api_base_url") }
    }

    // MARK: - User Settings (from API)

    var userSettings: UserSettings?
    var isLoadingSettings = false
    var settingsError: String?

    func fetchUserSettings() {
        guard hasAPIKey else { return }
        isLoadingSettings = true
        settingsError     = nil
        Task {
            defer { isLoadingSettings = false }
            do {
                userSettings = try await WallhavenFetch.shared.userSettings()
            } catch let wallhavenError as WallhavenError {
                settingsError = wallhavenError.errorDescription
            } catch {
                settingsError = error.localizedDescription
            }
        }
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
