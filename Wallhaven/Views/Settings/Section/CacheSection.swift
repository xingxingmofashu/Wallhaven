import SwiftUI

struct CacheSection: View {
    let onClear: () -> Void

    @State private var showAlert = false
    @State private var showToast  = false

    var body: some View {
        Section("Cache") {
            Button("Clear Image Cache") {
                showAlert = true
            }
            .alert("Clear Cache", isPresented: $showAlert) {
                Button("Clear", role: .destructive) {
                    onClear()
                    showToast = true
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        withAnimation { showToast = false }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear the in-memory image cache.")
            }
            .foregroundColor(.red)

            if showToast {
                Label("Cache Cleared", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: showToast)
    }
}
