import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteWallpaper.addedAt, order: .reverse)
    private var favorites: [FavoriteWallpaper]

    @State private var selectedWallpaper: Wallpaper?
    @State private var showDeleteAlert  = false

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    emptyView
                } else {
                    gridView
                }
            }
            .navigationTitle("Favorites")
            .toolbar {
                if !favorites.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .alert("Clear All Favorites", isPresented: $showDeleteAlert) {
                Button("Clear", role: .destructive) {
                    try? modelContext.delete(model: FavoriteWallpaper.self)
                    try? modelContext.save()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all local favorites. This cannot be undone.")
            }
            .navigationDestination(item: $selectedWallpaper) { wallpaper in
                let wallpapers = favorites.map(\.asWallpaper)
                let index = wallpapers.firstIndex(where: { $0.id == wallpaper.id }) ?? 0
                if wallpapers.indices.contains(index) {
                    DetailView(wallpapers: wallpapers, startIndex: index)
                }
            }
            .onChange(of: favorites) { _, newFavorites in
                guard let selected = selectedWallpaper,
                      !newFavorites.contains(where: { $0.wallpaperID == selected.id })
                else { return }
                selectedWallpaper = nil
            }
        }
    }

    // MARK: - Grid

    private var gridView: some View {
        let wallpapers = favorites.map(\.asWallpaper)
        return GridView(
            wallpapers: wallpapers,
            onSelect: { selectedWallpaper = $0 },
            contextMenu: { wallpaper in
                AnyView(
                    Button(role: .destructive) {
                        let wallpaperID = wallpaper.id
                        DispatchQueue.main.async {
                            let descriptor = FetchDescriptor<FavoriteWallpaper>(
                                predicate: #Predicate { $0.wallpaperID == wallpaperID }
                            )
                            if let favoriteWallpaper = try? modelContext.fetch(descriptor).first {
                                modelContext.delete(favoriteWallpaper)
                                try? modelContext.save()
                            }
                        }
                    } label: {
                        Label("Remove from Favorites", systemImage: "heart.slash")
                    }
                )
            }
        )
    }

    // MARK: - Empty

    private var emptyView: some View {
        ContentUnavailableView(
            "No Favorites Yet",
            systemImage: "heart",
            description: Text("Tap the heart icon on any wallpaper detail to save it here.")
        )
    }
}

#Preview {
    FavoritesView()
        .modelContainer(for: FavoriteWallpaper.self, inMemory: true)
}
