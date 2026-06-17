import SwiftUI

struct LoadingView: View {
    var message: LocalizedStringKey = "Loading…"

    var body: some View {
        ProgressView(message)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
