import SwiftUI

struct APISectionView: View {
    let viewModel: SettingsViewModel

    @State private var showAPIKeyField = false
    @State private var tempAPIKey      = ""
    @State private var showUsernameField = false
    @State private var tempUsername      = ""

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
            Text("API Key and username can be found in your wallhaven.cc account settings. API Key enables NSFW content and personal preferences.")
        }
    }
}
