import SwiftUI

struct AboutSectionView: View {
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
            Link("Website", destination: URL(string: "https://wallhaven.cc")!)
            Link("Documentation", destination: URL(string: "https://wallhaven.cc/help/api")!)
        }
    }
}
