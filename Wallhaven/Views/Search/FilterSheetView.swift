import SwiftUI

struct FilterSheetView: View {
    @Binding var filters: SearchFilters
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                FilterSheetSection(filters: $filters)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Reset") { filters = SearchFilters() }
                        .foregroundStyle(.red)
                }
            }
        }
    }
}

#Preview {
    FilterSheetView(filters: .constant(SearchFilters()), onApply: {})
}
