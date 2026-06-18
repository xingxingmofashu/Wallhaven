import SwiftUI

struct UserSettingsView: View {
    var body: some View {
        Group {
            if UserSettingsStore.shared.isLoading {
                LoadingView()
            } else if let settings = UserSettingsStore.shared.settings {
                List {
                    UserSettingsSection(settings: settings)
                }
            } else {
                ContentUnavailableView(
                    "API Key Required",
                    systemImage: "key",
                    description: Text("Set your Wallhaven API Key in Settings to view user settings.")
                )
            }
        }
        .navigationTitle("User Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
