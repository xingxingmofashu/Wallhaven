import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteWallpaper.addedAt, order: .reverse)
    private var favorites: [FavoriteWallpaper]

    @State private var favoritesViewModel = FavoritesViewModel()
    @State private var selectedFavorite: FavoriteWallpaper?
    @State private var showDeleteAlert  = false

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 8)]

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
                        .tint(.red)
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
        }
    }

    // MARK: - Grid

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(favorites) { fav in
                    Button {
                        // No navigation needed for favorites — show context menu only
                    } label: {
                        CellView(wallpaper: fav.asWallpaper)
                    }
                    .buttonStyle(.plain)
                    .aspectRatio(fav.aspectRatio, contentMode: .fit)
                    .contextMenu {
                        Button(role: .destructive) {
                            modelContext.delete(fav)
                            try? modelContext.save()
                        } label: {
                            Label("Remove from Favorites", systemImage: "heart.slash")
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
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
