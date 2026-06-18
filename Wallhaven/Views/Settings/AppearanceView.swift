import SwiftUI

struct AppearanceView: View {
    @Binding var appearance: Int
    let onSelect: (Int) -> Void

    private let options = ["Automatic", "Dark", "Light"]

    var body: some View {
        List {
            ForEach(0..<3, id: \.self) { index in
                Button {
                    appearance = index
                    onSelect(index)
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
    }
}
