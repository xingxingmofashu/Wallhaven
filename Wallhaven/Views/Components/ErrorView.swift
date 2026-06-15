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

#Preview {
    ErrorView(message: "Network connection timed out, please check your network and try again") {}
}
