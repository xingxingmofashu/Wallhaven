import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteWallpaper.addedAt, order: .reverse)
    private var favorites: [FavoriteWallpaper]

    @State private var favoritesViewModel = FavoritesViewModel()
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
                    favoritesViewModel.clearAll(context: modelContext)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all local favorites. This cannot be undone.")
            }
            .navigationDestination(item: $selectedWallpaper) { wallpaper in
                DetailView(wallpaper: wallpaper, relatedWallpapers: favorites.map(\.asWallpaper))
            }
        }
    }

    // MARK: - Grid

    private var gridView: some View {
        GridView(
            wallpapers: favorites.map(\.asWallpaper),
            onSelect: { selectedWallpaper = $0 },
            contextMenu: { wallpaper in
                AnyView(
                    Button(role: .destructive) {
                        let wallpaperID = wallpaper.id
                        let descriptor = FetchDescriptor<FavoriteWallpaper>(
                            predicate: #Predicate { $0.wallpaperID == wallpaperID }
                        )
                        if let favoriteWallpaper = try? modelContext.fetch(descriptor).first {
                            modelContext.delete(favoriteWallpaper)
                            try? modelContext.save()
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
