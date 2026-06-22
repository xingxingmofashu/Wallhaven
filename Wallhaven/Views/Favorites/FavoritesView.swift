import SwiftUI
import SwiftData

// MARK: - Favorites & Collections

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<FavoriteWallpaper> { $0.collectionID == nil },
        sort: \FavoriteWallpaper.addedAt, order: .reverse
    )
    private var favorites: [FavoriteWallpaper]

    @State private var selectedTab = TabSection.favorites
    @State private var selectedWallpaper: Wallpaper?
    @State private var showDeleteAlert = false

    enum TabSection: String, CaseIterable {
        case favorites   = "Favorites"
        case collections = "Collections"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedTab) {
                    ForEach(TabSection.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Group {
                    switch selectedTab {
                    case .favorites:
                        FavoritesTab(
                            wallpapers: favorites.map(\.asWallpaper),
                            onSelect: { selectedWallpaper = $0 },
                            removeFavorite: { wallpaperID in
                                modelContext.deferredDelete(
                                    where: #Predicate { $0.wallpaperID == wallpaperID && $0.collectionID == nil }
                                )
                            }
                        )
                    case .collections:
                        CollectionsTab()
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if selectedTab == .favorites && !favorites.isEmpty {
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
                    let descriptor = FetchDescriptor<FavoriteWallpaper>(
                        predicate: #Predicate { $0.collectionID == nil }
                    )
                    if let items = try? modelContext.fetch(descriptor) {
                        for item in items {
                            modelContext.delete(item)
                        }
                    modelContext.saveWithLog()
                    }
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
        }
    }
}
