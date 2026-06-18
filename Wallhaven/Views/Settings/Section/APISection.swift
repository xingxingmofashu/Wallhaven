import SwiftUI

struct APISection: View {
    let viewModel: SettingsViewModel

    @State private var showAPIKeyField = false
    @State private var tempAPIKey      = ""

    var body: some View {
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

            if viewModel.hasApiKey {
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
