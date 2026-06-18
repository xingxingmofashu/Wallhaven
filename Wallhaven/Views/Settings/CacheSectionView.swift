import SwiftUI

struct CacheSectionView: View {
    let onClear: () -> Void
    let onCacheCleared: () -> Void

    @State private var showAlert = false

    var body: some View {
        Section("Cache") {
            Button("Clear Image Cache") {
                showAlert = true
            }
            .alert("Clear Cache", isPresented: $showAlert) {
                Button("Clear", role: .destructive) {
                    onClear()
                    onCacheCleared()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear the in-memory image cache.")
            }
            .foregroundColor(.red)
        }
    }
}
