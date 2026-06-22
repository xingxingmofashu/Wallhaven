import SwiftUI
import SwiftData

struct CollectionsTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CollectionFolder.sortOrder)
    private var collections: [CollectionFolder]
    @Query private var allItems: [StoredWallpaper]

    private var collectionCounts: [UUID: Int] {
        Dictionary(grouping: allItems.compactMap(\.collectionID), by: { $0 })
            .mapValues(\.count)
    }

    @State private var showCreateAlert = false
    @State private var showRenameAlert = false
    @State private var newCollectionName = ""
    @State private var renameText = ""
    @State private var renameCollection: CollectionFolder?

    private let collectionsVM = CollectionsViewModel()

    var body: some View {
        collectionListView
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
                        NavigationLink(value: collection) {
                            CollectionRowView(
                                name: collection.name,
                                count: collectionCounts[collection.id] ?? 0
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
        .navigationDestination(for: CollectionFolder.self) { collection in
            CollectionWallpapersView(collection: collection)
        }
    }
}

// MARK: - Collection Wallpapers

struct CollectionWallpapersView: View {
    @Environment(\.modelContext) private var modelContext
    let collection: CollectionFolder

    @State private var wallpapers: [Wallpaper] = []
    @State private var selectedWallpaper: Wallpaper?

    var body: some View {
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
                        Button(role: .destructive) {
                            removeFromCollection(wallpaperID: wallpaper.id)
                        } label: {
                            Label("Remove from Collection", systemImage: "star.slash")
                        }
                    }
                )
            }
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedWallpaper) { wallpaper in
            if let index = wallpapers.firstIndex(where: { $0.id == wallpaper.id }),
               wallpapers.indices.contains(index)
            {
                DetailView(wallpapers: wallpapers, startIndex: index)
            }
        }
        .task {
            loadWallpapers()
        }
    }

    private func loadWallpapers() {
        let collectionID = collection.id
        let descriptor = FetchDescriptor<StoredWallpaper>(
            predicate: #Predicate { $0.collectionID == collectionID },
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        if let items = try? modelContext.fetch(descriptor) {
            wallpapers = items.map(\.asWallpaper)
        }
    }

    private func removeFromCollection(wallpaperID: String) {
        let collectionID = collection.id
        DispatchQueue.main.async {
            let descriptor = FetchDescriptor<StoredWallpaper>(
                predicate: #Predicate {
                    $0.wallpaperID == wallpaperID && $0.collectionID == collectionID
                }
            )
            if let item = try? modelContext.fetch(descriptor).first {
                modelContext.delete(item)
                modelContext.saveWithLog()
                loadWallpapers()
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
