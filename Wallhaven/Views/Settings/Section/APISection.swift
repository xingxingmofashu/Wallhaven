import SwiftUI

struct APISection: View {
    let apiBaseURL: String
    let hasApiKey: Bool
    let apiKey: String
    let onSaveKey: (String) -> Void

    @State private var showAPIKeyField = false
    @State private var tempAPIKey      = ""

    var body: some View {
        Section {
            HStack {
                Text("Default URL")
                Spacer()
                Text(apiBaseURL)
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
