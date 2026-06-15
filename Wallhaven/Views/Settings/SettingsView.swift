import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showAPIKeyField = false
    @State private var tempAPIKey      = ""
    @State private var showClearCacheAlert = false
    @State private var showClearedToast   = false

    var body: some View {
        NavigationStack {
            Form {
                apiKeySection
                if viewModel.hasAPIKey { remoteSettingsSection }
                cacheSection
                aboutSection
            }
            .navigationTitle("Settings")
            .task {
                tempAPIKey = viewModel.apiKey
                if viewModel.hasAPIKey { viewModel.fetchUserSettings() }
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

    // MARK: - API Key Section

    private var apiKeySection: some View {
        Section {
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
        } header: {
            Text("Wallhaven API Key")
        } footer: {
            Text("API Key can be found in your wallhaven.cc account settings. Enables NSFW content and personal preferences.")
        }
    }

    // MARK: - Remote Settings Section

    private var remoteSettingsSection: some View {
        Section("Account Preferences (from Wallhaven)") {
            if viewModel.isLoadingSettings {
                HStack {
                    ProgressView()
                    Text("Syncing…").foregroundStyle(.secondary)
                }
            } else if let s = viewModel.userSettings {
                settingsRow("Default Purity",  value: s.purity.joined(separator: ", "))
                settingsRow("Default Categories",  value: s.categories.joined(separator: ", "))
                settingsRow("Preferred Resolutions", value: s.resolutions.isEmpty ? "Any" : s.resolutions.joined(separator: ", "))
                settingsRow("Preferred Ratios",  value: s.aspectRatios.isEmpty ? "Any" : s.aspectRatios.joined(separator: ", "))
                settingsRow("Toplist Range", value: s.toplistRange)
            } else if let err = viewModel.settingsError {
                Label(err, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
        }
    }

    private func settingsRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline)
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
            Link("Wallhaven Website", destination: URL(string: "https://wallhaven.cc")!)
            Link("API Documentation", destination: URL(string: "https://wallhaven.cc/help/api")!)
        }
    }
}

#Preview {
    SettingsView()
}
