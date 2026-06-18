import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showClearedToast = false
    @AppStorage("app_appearance") private var appAppearance = 0

    var body: some View {
        NavigationStack {
            Form {
                GeneralSectionView(appearance: $appAppearance, onAppearanceChange: applyAppearance)
                APISectionView(viewModel: viewModel)
                CacheSectionView(onClear: viewModel.clearImageCache, onCacheCleared: handleCacheCleared)
                AboutSectionView(version: viewModel.appVersion, buildNumber: viewModel.buildNumber)
            }
            .navigationTitle("Settings")
            .task {
                applyAppearance(appAppearance)
                await viewModel.fetchUserSettings()
            }
            .onChange(of: viewModel.hasApiKey) { _, _ in
                Task { await viewModel.fetchUserSettings() }
            }
            .overlay(alignment: .bottom) {
                if showClearedToast {
                    Label("Cache Cleared", systemImage: "checkmark.circle.fill")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private func applyAppearance(_ value: Int) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        switch value {
        case 1:  scene.windows.forEach { $0.overrideUserInterfaceStyle = .dark }
        case 2:  scene.windows.forEach { $0.overrideUserInterfaceStyle = .light }
        default: scene.windows.forEach { $0.overrideUserInterfaceStyle = .unspecified }
        }
    }

    private func handleCacheCleared() {
        withAnimation { showClearedToast = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { showClearedToast = false }
        }
    }
}

#Preview {
    SettingsView()
}
