import SwiftUI

struct LoadingView: View {
    let message: LocalizedStringKey

    init(_ message: LocalizedStringKey = "Loading…") {
        self.message = message
    }

    var body: some View {
        ProgressView(message)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
