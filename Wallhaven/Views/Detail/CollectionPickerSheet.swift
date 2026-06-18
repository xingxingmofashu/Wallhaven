import SwiftUI

struct CollectionPickerSheet: View {
    let collections: [CollectionFolder]
    let onSelect: (UUID) -> Void
    let onCreateNew: (String) -> Void

    @State private var showCreateField = false
    @State private var newName = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(collections) { collection in
                    Button {
                        onSelect(collection.id)
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                            Text(collection.name)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }

                if showCreateField {
                    HStack {
                        TextField("Collection name", text: $newName)
                        Button("Save") {
                            let name = newName.trimmingCharacters(in: .whitespaces)
                            if !name.isEmpty {
                                onCreateNew(name)
                            }
                        }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } else {
                    Button {
                        showCreateField = true
                    } label: {
                        Label("New Collection", systemImage: "folder.badge.plus")
                    }
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
