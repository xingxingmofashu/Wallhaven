import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showAPIKeyField = false
    @State private var tempAPIKey      = ""
    @State private var showUsernameField = false
    @State private var tempUsername      = ""
    @State private var showClearCacheAlert = false
    @State private var showClearedToast   = false
    @AppStorage("app_appearance") private var appAppearance = 0

    var body: some View {
        NavigationStack {
            Form {
                generalSection
                apiSection
                userSettingsSection
                cacheSection
                aboutSection
            }
            .navigationTitle("Settings")
            .task {
                tempAPIKey = viewModel.apiKey
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

            NavigationLink {
                AppearanceView(appearance: $appAppearance, onSelect: applyAppearance)
            } label: {
                HStack {
                    Text("Appearance")
                    Spacer()
                    Text(appearanceName)
                        .foregroundStyle(.secondary)
                }
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

    private var appearanceName: String {
        switch appAppearance {
        case 1:  return "Dark"
        case 2:  return "Light"
        default: return "Automatic"
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

            HStack {
                Text("Username")
                Spacer()
                if showUsernameField {
                    TextField("wallhaven.cc username", text: $tempUsername)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .multilineTextAlignment(.trailing)
                    Button("Save") {
                        viewModel.wallhavenUsername = tempUsername.trimmingCharacters(in: .whitespaces)
                        showUsernameField = false
                    }
                    .fontWeight(.semibold)
                } else {
                    Text(viewModel.wallhavenUsername.isEmpty ? "Not set" : viewModel.wallhavenUsername)
                        .foregroundStyle(.secondary)
                    Button(viewModel.wallhavenUsername.isEmpty ? "Set" : "Change") {
                        tempUsername = viewModel.wallhavenUsername
                        showUsernameField = true
                    }
                    .font(.subheadline)
                }
            }

            if showAPIKeyField {
                HStack {
                    SecureField("Paste API Key", text: $tempAPIKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button("Save") {
                        viewModel.apiKey = tempAPIKey.trimmingCharacters(in: .whitespaces)
                        showAPIKeyField  = false
                    }
                    .fontWeight(.semibold)
                }
            } else {
                HStack {
                    Label(
                        viewModel.hasApiKey ? "API Key Set" : "No API Key",
                        systemImage: viewModel.hasApiKey ? "key.fill" : "key"
                    )
                    .foregroundStyle(viewModel.hasApiKey ? .green : .secondary)
                    Spacer()
                    Button(viewModel.hasApiKey ? "Change" : "Set") {
                        tempAPIKey = viewModel.apiKey
                        showAPIKeyField = true
                    }
                    .font(.subheadline)
                }
            }
        } header: {
            Text("Wallhaven API")
        } footer: {
            Text("API Key and username can be found in your wallhaven.cc account settings. API Key enables NSFW content and personal preferences.")
        }
    }

    // MARK: - User Settings Section

    private var userSettingsSection: some View {
        Section("User Settings") {
            if viewModel.isLoadingSettings {
                LoadingView(message: "Loading…")
            } else if let settings = viewModel.userSettings {
                LabeledContent("Thumb Size", value: settings.thumbSize)
                LabeledContent("Per Page", value: settings.perPage)
                LabeledContent("Purity", value: settings.purity.joined(separator: ", "))
                LabeledContent("Categories", value: settings.categories.joined(separator: ", "))
                if !settings.resolutions.isEmpty {
                    LabeledContent("Resolutions", value: settings.resolutions.joined(separator: ", "))
                }
                if !settings.aspectRatios.isEmpty {
                    LabeledContent("Aspect Ratios", value: settings.aspectRatios.joined(separator: ", "))
                }
                LabeledContent("Toplist Range", value: settings.toplistRange)
                if !settings.tagBlacklist.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tag Blacklist").font(.subheadline).foregroundStyle(.secondary)
                        ForEach(settings.tagBlacklist, id: \.self) { tag in
                            Text(tag).font(.caption)
                        }
                    }
                }
            }
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
            .foregroundColor(.red)
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

// MARK: - Appearance View

struct AppearanceView: View {
    @Binding var appearance: Int
    let onSelect: (Int) -> Void

    private let options = ["Automatic", "Dark", "Light"]

    var body: some View {
        List {
            ForEach(0..<3, id: \.self) { index in
                Button {
                    appearance = index
                    onSelect(index)
                } label: {
                    HStack {
                        Text(options[index])
                        Spacer()
                        if appearance == index {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .foregroundStyle(.foreground)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}
