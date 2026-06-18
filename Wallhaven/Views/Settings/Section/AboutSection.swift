import SwiftUI

struct AboutSection: View {
    let version: String
    let buildNumber: String

    var body: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("\(version) (\(buildNumber))")
                    .foregroundStyle(.secondary)
            }
            if let url = URL(string: "https://wallhaven.cc") {
                Link("Website", destination: url)
            }
            if let url = URL(string: "https://wallhaven.cc/help/api") {
                Link("Documentation", destination: url)
            }
            if let url = URL(string: "https://github.com/xingxingmofashu/Wallhaven") {
                Link("GitHub", destination: url)
            }
            if let url = URL(string: "https://github.com/xingxingmofashu/Wallhaven/blob/main/LICENSE") {
                Link("License", destination: url)
            }
            if let url = URL(string: "https://github.com/xingxingmofashu/Wallhaven/blob/main/PRIVACY.md") {
                Link("Privacy Policy", destination: url)
            }
        }
    }
}
