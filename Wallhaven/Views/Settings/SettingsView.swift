import SwiftUI

struct SettingsView: View {
    @AppStorage("app_appearance") private var appAppearance = 0

    var body: some View {
        NavigationStack {
            Form {
                GeneralSection(appearance: $appAppearance)
                APISection(
                    apiBaseURL: SettingsViewModel.shared.apiBaseURL,
                    hasApiKey: SettingsViewModel.shared.hasApiKey,
                    apiKey: SettingsViewModel.shared.apiKey,
                    onSaveKey: { SettingsViewModel.shared.apiKey = $0 }
                )
                CacheSection(onClear: SettingsViewModel.shared.clearImageCache)
                AboutSection(version: SettingsViewModel.shared.appVersion, buildNumber: SettingsViewModel.shared.buildNumber)
            }
            .navigationTitle("Settings")
            .task { await SettingsViewModel.shared.load() }
            .onChange(of: SettingsViewModel.shared.hasApiKey) { _, _ in
                Task { await SettingsViewModel.shared.load() }
            }
        }
    }
}

#Preview {
    SettingsView()
}
