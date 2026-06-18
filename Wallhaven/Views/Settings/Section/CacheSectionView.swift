import SwiftUI

struct CacheSectionView: View {
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
        }
        .overlay(alignment: .bottom) {
            if showToast {
                Label("Cache Cleared", systemImage: "checkmark.circle.fill")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .padding(.bottom, -30)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.default, value: showToast)
    }
}
