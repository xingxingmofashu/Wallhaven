import SwiftUI

struct UserSettingsView: View {
    var body: some View {
        Group {
            if UserSettingsStore.shared.isLoading {
                LoadingView()
            } else if let settings = UserSettingsStore.shared.settings {
                settingsList(settings)
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

    private func settingsList(_ settings: UserSettings) -> some View {
        List {
            Section {
                LabeledContent("Thumb Size", value: settings.thumbSize)
                LabeledContent("Per Page", value: settings.perPage)
                LabeledContent("Purity", value: settings.purity.joined(separator: ", "))
                LabeledContent("Categories", value: settings.categories.joined(separator: ", "))
                LabeledContent("Toplist Range", value: settings.toplistRange)
            }

            if !settings.resolutions.isEmpty {
                Section("Resolutions") {
                    ForEach(settings.resolutions, id: \.self) { res in
                        Text(res)
                    }
                }
            }

            if !settings.aspectRatios.isEmpty {
                Section("Aspect Ratios") {
                    ForEach(settings.aspectRatios, id: \.self) { ratio in
                        Text(ratio)
                    }
                }
            }

            if !settings.tagBlacklist.isEmpty {
                Section("Tag Blacklist") {
                    ForEach(settings.tagBlacklist, id: \.self) { tag in
                        Text(tag)
                    }
                }
            }
        }
    }
}
