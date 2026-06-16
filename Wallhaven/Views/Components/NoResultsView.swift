import SwiftUI

/// Empty result state view
struct NoResultsView: View {
    var message: LocalizedStringKey = "No wallpapers found"

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.title2.weight(.medium))
            Text("Try different keywords or filter conditions")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
