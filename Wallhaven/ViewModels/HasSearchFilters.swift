import Foundation

protocol HasSearchFilters: AnyObject {
    var filters: SearchFilters { get set }
    var didApplyDefaults: Bool { get set }
}

extension HasSearchFilters {
    @MainActor
    func applyWebsiteDefaults() {
        guard !didApplyDefaults, let settings = SettingsViewModel.shared.settings else { return }
        filters.applyWebsiteDefaults(from: settings)
        didApplyDefaults = true
    }
}
