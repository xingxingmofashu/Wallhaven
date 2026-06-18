import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @AppStorage("app_appearance") private var appAppearance = 0

    var body: some View {
        NavigationStack {
            Form {
                GeneralSectionView(appearance: $appAppearance)
                APISectionView(viewModel: viewModel)
                CacheSectionView(onClear: viewModel.clearImageCache)
                AboutSectionView(version: viewModel.appVersion, buildNumber: viewModel.buildNumber)
            }
            .navigationTitle("Settings")
            .task { await viewModel.fetchUserSettings() }
            .onChange(of: viewModel.hasApiKey) { _, _ in
                Task { await viewModel.fetchUserSettings() }
            }
        }
    }
}

#Preview {
    SettingsView()
}
