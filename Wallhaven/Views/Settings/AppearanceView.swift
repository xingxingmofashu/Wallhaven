import SwiftUI

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
                        Spacer()
                        if appearance == index {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .foregroundStyle(.foreground)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { applyAppearance(appearance) }
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
