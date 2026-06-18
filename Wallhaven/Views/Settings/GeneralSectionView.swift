import SwiftUI

struct GeneralSectionView: View {
    @Binding var appearance: Int
    let onAppearanceChange: (Int) -> Void

    var body: some View {
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
                AppearanceView(appearance: $appearance, onSelect: onAppearanceChange)
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
        switch appearance {
        case 1:  return "Dark"
        case 2:  return "Light"
        default: return "Automatic"
        }
    }
}
