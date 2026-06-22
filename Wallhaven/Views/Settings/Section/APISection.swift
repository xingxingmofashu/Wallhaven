import SwiftUI

struct APISection: View {
    let hasApiKey: Bool
    let apiKey: String
    let onSaveKey: (String) -> Void
    let onSaveURL: (String) -> Void

    private var apiBaseURL: String { SettingsViewModel.shared.apiBaseURL }

    @State private var showAPIKeyField = false
    @State private var tempAPIKey      = ""
    @State private var showURLField    = false
    @State private var tempURL         = ""

    var body: some View {
        Section {
            if showURLField {
                HStack {
                    TextField("https://wallhaven.cc/api/v1", text: $tempURL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    Button("Save") {
                        onSaveURL(tempURL.trimmingCharacters(in: .whitespaces))
                        showURLField = false
                    }
                    .fontWeight(.semibold)
                }
            } else {
                HStack {
                    Text("Default URL")
                    Spacer()
                    Text(apiBaseURL)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Button("Edit") {
                        tempURL = apiBaseURL
                        showURLField = true
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
                        onSaveKey(tempAPIKey.trimmingCharacters(in: .whitespaces))
                        showAPIKeyField  = false
                    }
                    .fontWeight(.semibold)
                }
            } else {
                HStack {
                    Label(
                        hasApiKey ? "API Key Set" : "No API Key",
                        systemImage: hasApiKey ? "key.fill" : "key"
                    )
                    .foregroundStyle(hasApiKey ? .green : .secondary)
                    Spacer()
                    Button(hasApiKey ? "Change" : "Set") {
                        tempAPIKey = apiKey
                        showAPIKeyField = true
                    }
                    .font(.subheadline)
                }
            }

            if hasApiKey {
                NavigationLink {
                    UserSettingsView()
                } label: {
                    HStack {
                        Text("User Settings")
                        Spacer()
                        Text("Configured")
                            .foregroundStyle(.green, .secondary)
                            .font(.subheadline)
                    }
                }
            }
        } header: {
            Text("Wallhaven API")
        } footer: {
            Text("API Key can be found in your wallhaven.cc account settings. Enables NSFW content and personal preferences.")
        }
    }
}
