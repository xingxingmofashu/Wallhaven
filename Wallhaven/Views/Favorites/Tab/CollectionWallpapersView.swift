import SwiftUI
import SwiftData

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
        let descriptor = FetchDescriptor<FavoriteWallpaper>(
            predicate: #Predicate { $0.collectionID == collectionID },
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        if let items = try? modelContext.fetch(descriptor) {
            wallpapers = items.map(\.asWallpaper)
        }
    }

    private func removeFromCollection(wallpaperID: String) {
        let collectionID = collection.id
        modelContext.deferredDelete(
            where: #Predicate { $0.wallpaperID == wallpaperID && $0.collectionID == collectionID }
        ) {
            loadWallpapers()
        }
    }
}
