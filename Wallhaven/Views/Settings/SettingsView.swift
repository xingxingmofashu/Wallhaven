import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showAPIKeyField = false
    @State private var tempAPIKey      = ""
    @State private var showClearCacheAlert = false
    @State private var showClearedToast   = false
    @AppStorage("app_appearance") private var appAppearance = 0

    var body: some View {
        NavigationStack {
            Form {
                generalSection
                apiSection
                cacheSection
                aboutSection
            }
            .navigationTitle("Settings")
            .task {
                tempAPIKey = viewModel.apiKey
                if viewModel.hasAPIKey { viewModel.fetchUserSettings() }
                applyAppearance(appAppearance)
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

    // MARK: - General Section

    private var generalSection: some View {
        Section {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Text("App Language")
                    Spacer()
                    Text(currentLanguageName)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.primary)

            Picker("Appearance", selection: $appAppearance) {
                Text("Automatic").tag(0)
                Text("Dark").tag(1)
                Text("Light").tag(2)
            }
            .onChange(of: appAppearance) { _, newValue in
                applyAppearance(newValue)
            }
        }
    }

    private var currentLanguageName: String {
        let code = Locale.preferredLanguages.first?.prefix(2).description ?? "en"
        switch code {
        case "zh":  return "简体中文"
        default:    return "English"
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

    // MARK: - API Section

    private var apiSection: some View {
        Section {
            HStack {
                Text("Default URL")
                Spacer()
                Text(viewModel.apiBaseURL)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if showAPIKeyField {
                HStack {
                    SecureField("Paste API Key", text: $tempAPIKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button("Save") {
                        viewModel.apiKey = tempAPIKey.trimmingCharacters(in: .whitespaces)
                        showAPIKeyField  = false
                        if viewModel.hasAPIKey { viewModel.fetchUserSettings() }
                    }
                    .fontWeight(.semibold)
                }
            } else {
                HStack {
                    Label(
                        viewModel.hasAPIKey ? "API Key Set" : "No API Key",
                        systemImage: viewModel.hasAPIKey ? "key.fill" : "key"
                    )
                    .foregroundStyle(viewModel.hasAPIKey ? .green : .secondary)
                    Spacer()
                    Button(viewModel.hasAPIKey ? "Change" : "Set") {
                        tempAPIKey = viewModel.apiKey
                        showAPIKeyField = true
                    }
                    .font(.subheadline)
                }

                if viewModel.hasAPIKey {
                    Button("Clear API Key", role: .destructive) {
                        viewModel.apiKey = ""
                        tempAPIKey = ""
                    }
                }
            }

            if viewModel.hasAPIKey {
                Divider()

                if viewModel.isLoadingSettings {
                    HStack {
                        ProgressView()
                        Text("Syncing…").foregroundStyle(.secondary)
                    }
                } else if let userSettings = viewModel.userSettings {
                    settingsRow("Default Purity", value: userSettings.purity.joined(separator: ", "))
                    settingsRow("Default Categories", value: userSettings.categories.joined(separator: ", "))
                    settingsRow("Preferred Resolutions", value: userSettings.resolutions.isEmpty ? "Any" : userSettings.resolutions.joined(separator: ", "))
                    settingsRow("Preferred Ratios", value: userSettings.aspectRatios.isEmpty ? "Any" : userSettings.aspectRatios.joined(separator: ", "))
                    settingsRow("Toplist Range", value: userSettings.toplistRange)
                } else if let settingsError = viewModel.settingsError {
                    Label(settingsError, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }
        } header: {
            Text("Wallhaven API")
        } footer: {
            Text("API Key can be found in your wallhaven.cc account settings. Enables NSFW content and personal preferences.")
        }
    }

    private func settingsRow(_ labelKey: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(labelKey)
            Spacer()
            Text(value).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    // MARK: - Cache Section

    private var cacheSection: some View {
        Section("Cache") {
            Button("Clear Image Cache") {
                showClearCacheAlert = true
            }
            .alert("Clear Cache", isPresented: $showClearCacheAlert) {
                Button("Clear", role: .destructive) {
                    viewModel.clearImageCache()
                    withAnimation {
                        showClearedToast = true
                    }
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        withAnimation { showClearedToast = false }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear the in-memory image cache.")
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("\(viewModel.appVersion) (\(viewModel.buildNumber))")
                    .foregroundStyle(.secondary)
            }
            Link("Website", destination: URL(string: "https://wallhaven.cc")!)
            Link("Documentation", destination: URL(string: "https://wallhaven.cc/help/api")!)
        }
    }
}

#Preview {
    SettingsView()
}
