import SwiftUI

/// Empty result state view
struct EmptyView: View {
    var message: String = "No wallpapers found"

    var body: some View {
        ContentUnavailableView(
            message,
            systemImage: "photo.on.rectangle.angled",
            description: Text("Try different keywords or filter conditions")
        )
    }
}
