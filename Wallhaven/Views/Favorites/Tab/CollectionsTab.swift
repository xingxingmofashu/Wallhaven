import SwiftUI
import SwiftData

struct CollectionsTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WallhavenCollection.sortOrder)
    private var collections: [WallhavenCollection]
    @Query private var allItems: [CollectionItem]

    @State private var showCreateAlert = false
    @State private var showRenameAlert = false
    @State private var newCollectionName = ""
    @State private var renameText = ""
    @State private var renameCollection: WallhavenCollection?
    @State private var selectedCollection: WallhavenCollection?

    @State private var wallpapers: [Wallpaper] = []
    @State private var selectedWallpaper: Wallpaper?

    private let collectionsVM = CollectionsViewModel()

    var body: some View {
        Group {
            if let collection = selectedCollection {
                wallpapersView(for: collection)
            } else {
                collectionListView
            }
        }
        .toolbar {
            if selectedCollection == nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateAlert = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
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
        .alert("Rename Collection", isPresented: $showRenameAlert) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) {
                renameCollection = nil
            }
            Button("Rename") {
                let name = renameText.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty, let collection = renameCollection {
                    collectionsVM.renameCollection(collection, to: name, in: modelContext)
                }
                renameCollection = nil
            }
        } message: {
            Text("Enter a new name for this collection.")
        }
        .task {
            collectionsVM.ensureDefaultCollection(in: modelContext)
        }
    }

    // MARK: - Collection List

    private var collectionListView: some View {
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
                        Button {
                            selectedCollection = collection
                            loadWallpapers(for: collection)
                        } label: {
                            CollectionRowView(
                                name: collection.name,
                                count: allItems.filter { $0.collectionID == collection.id }.count
                            )
                        }
                        .contextMenu {
                            Button {
                                renameText = collection.name
                                renameCollection = collection
                                showRenameAlert = true
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                collectionsVM.deleteCollection(collection, in: modelContext)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
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
        .navigationTitle("Collections")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Wallpapers View

    private func wallpapersView(for collection: WallhavenCollection) -> some View {
        Group {
            if wallpapers.isEmpty {
                ContentUnavailableView(
                    "Empty Collection",
                    systemImage: "folder",
                    description: Text("No wallpapers in this collection.")
                )
            } else {
                GridView(
                    wallpapers: wallpapers,
                    onSelect: { selectedWallpaper = $0 },
                    contextMenu: { wallpaper in
                        AnyView(
                            Button(role: .destructive) {
                                removeFromCollection(wallpaperID: wallpaper.id)
                            } label: {
                                Label("Remove from Collection", systemImage: "star.slash")
                            }
                        )
                    }
                )
            }
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    selectedCollection = nil
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .navigationDestination(item: $selectedWallpaper) { wallpaper in
            if let index = wallpapers.firstIndex(where: { $0.id == wallpaper.id }),
               wallpapers.indices.contains(index)
            {
                DetailView(wallpapers: wallpapers, startIndex: index)
            }
        }
    }

    private func loadWallpapers(for collection: WallhavenCollection) {
        let collectionID = collection.id
        let descriptor = FetchDescriptor<CollectionItem>(
            predicate: #Predicate { $0.collectionID == collectionID },
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        if let items = try? modelContext.fetch(descriptor) {
            wallpapers = items.map(\.asWallpaper)
        }
    }

    private func removeFromCollection(wallpaperID: String) {
        guard let collection = selectedCollection else { return }
        let collectionID = collection.id
        DispatchQueue.main.async {
            let descriptor = FetchDescriptor<CollectionItem>(
                predicate: #Predicate {
                    $0.wallpaperID == wallpaperID && $0.collectionID == collectionID
                }
            )
            if let item = try? modelContext.fetch(descriptor).first {
                modelContext.delete(item)
                try? modelContext.save()
                loadWallpapers(for: collection)
            }
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
