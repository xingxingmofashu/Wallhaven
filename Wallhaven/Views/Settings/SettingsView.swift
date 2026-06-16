import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showAPIKeyField = false
    @State private var tempAPIKey      = ""
    @State private var showAPIURLField = false
    @State private var tempAPIURL      = ""
    @State private var showClearCacheAlert = false
    @State private var showClearedToast   = false

    var body: some View {
        NavigationStack {
            Form {
                apiKeySection
                apiURLSection
                if viewModel.hasAPIKey { remoteSettingsSection }
                cacheSection
                aboutSection
            }
            .navigationTitle("Settings")
            .task {
                tempAPIKey = viewModel.apiKey
                tempAPIURL = viewModel.apiBaseURL
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

    // MARK: - API URL Section

    private var apiURLSection: some View {
        Section {
            HStack {
                Text("Base URL")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.apiBaseURL)
                    .font(.subheadline)
                    .lineLimit(1)
            }

            if showAPIURLField {
                HStack {
                    TextField("New URL", text: $tempAPIURL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    Button("Save") {
                        viewModel.apiBaseURL = tempAPIURL.trimmingCharacters(in: .whitespaces)
                        showAPIURLField = false
                    }
                    .fontWeight(.semibold)
                }
            }

            Button(showAPIURLField ? "Cancel" : "Change URL") {
                withAnimation {
                    showAPIURLField.toggle()
                    tempAPIURL = viewModel.apiBaseURL
                }
            }
            .font(.subheadline)
        } header: {
            Text("API Endpoint")
        } footer: {
            Text("Default: https://wallhaven.cc/api/v1")
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
    }

    private func settingsRow(_ labelKey: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(labelKey).foregroundStyle(.secondary)
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
