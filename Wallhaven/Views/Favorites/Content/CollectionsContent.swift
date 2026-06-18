import SwiftUI
import SwiftData

struct CollectionsContent: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WallhavenCollection.sortOrder)
    private var collections: [WallhavenCollection]
    @Query private var allItems: [CollectionItem]

    @State private var showCreateAlert = false
    @State private var newCollectionName = ""

    private let collectionsVM = CollectionsViewModel()

    var body: some View {
        Group {
            if collections.isEmpty {
                ContentUnavailableView(
                    "No Collections",
                    systemImage: "folder",
                    description: Text("Tap the star icon on any wallpaper to create your first collection.")
                )
            } else {
                List {
                    ForEach(collections) { collection in
                        NavigationLink {
                            CollectionWallpapersView(collection: collection)
                        } label: {
                            CollectionRowView(
                                name: collection.name,
                                count: allItems.filter { $0.collectionID == collection.id }.count
                            )
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let collection = collections[index]
                            collectionsVM.deleteCollection(collection, in: modelContext)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCreateAlert = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
        .alert("New Collection", isPresented: $showCreateAlert) {
            TextField("Name", text: $newCollectionName)
            Button("Cancel", role: .cancel) {
                newCollectionName = ""
            }
            Button("Create") {
                let name = newCollectionName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    collectionsVM.createCollection(named: name, in: modelContext)
                }
                newCollectionName = ""
            }
        } message: {
            Text("Enter a name for the new collection.")
        }
        .task {
            collectionsVM.ensureDefaultCollection(in: modelContext)
        }
    }
}

// MARK: - Collection Row

struct CollectionRowView: View {
    let name: String
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.title3)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .fontWeight(.medium)
                Label(
                    String(format: NSLocalizedString("%d wallpapers", comment: "Number of wallpapers in a collection"), count),
                    systemImage: "photo.on.rectangle"
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
