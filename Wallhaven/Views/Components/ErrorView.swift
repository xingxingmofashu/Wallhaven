import SwiftUI

/// Generic error state view
struct ErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Loading Failed", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
                .multilineTextAlignment(.center)
        } actions: {
            Button("Retry", action: retryAction)
                .buttonStyle(.bordered)
        }
    }
}

/// Empty result state view
struct EmptyResultView: View {
    var message: String = "No wallpapers found"

    var body: some View {
        ContentUnavailableView(
            message,
            systemImage: "photo.on.rectangle.angled",
            description: Text("Try different keywords or filter conditions")
        )
    }
}

#Preview {
    ErrorView(message: "Network connection timed out, please check your network and try again") {}
}
