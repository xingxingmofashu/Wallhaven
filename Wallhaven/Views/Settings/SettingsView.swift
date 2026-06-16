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

            NavigationLink {
                AppearanceView(appearance: $appAppearance)
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
            }
        } header: {
            Text("Wallhaven API")
        } footer: {
            Text("API Key can be found in your wallhaven.cc account settings. Enables NSFW content and personal preferences.")
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

// MARK: - Appearance View

struct AppearanceView: View {
    @Binding var appearance: Int

    private let options = ["Automatic", "Dark", "Light"]

    var body: some View {
        List {
            ForEach(0..<3, id: \.self) { index in
                Button {
                    appearance = index
                    applyAppearance(index)
                } label: {
                    HStack {
                        Text(options[index])
                            .foregroundStyle(.primary)
                        Spacer()
                        if appearance == index {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func applyAppearance(_ value: Int) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        switch value {
        case 1:  scene.windows.forEach { $0.overrideUserInterfaceStyle = .dark }
        case 2:  scene.windows.forEach { $0.overrideUserInterfaceStyle = .light }
        default: scene.windows.forEach { $0.overrideUserInterfaceStyle = .unspecified }
        }
    }
}

#Preview {
    SettingsView()
}
