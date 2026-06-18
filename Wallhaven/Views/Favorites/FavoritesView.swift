import SwiftUI
import SwiftData

// MARK: - Favorites & Collections

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteWallpaper.addedAt, order: .reverse)
    private var favorites: [FavoriteWallpaper]

    @State private var selectedTab = TabSection.favorites
    @State private var collectionsVM = CollectionsViewModel()
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
                    case .favorites:   favoritesContent
                    case .collections: collectionsContent
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
            .onChange(of: selectedTab) { _, newValue in
                if newValue == .collections {
                    Task { await collectionsVM.loadCollections() }
                }
            }
        }
    }

    // MARK: - Favorites

    @ViewBuilder
    private var favoritesContent: some View {
        if favorites.isEmpty {
            ContentUnavailableView(
                "No Favorites Yet",
                systemImage: "heart",
                description: Text("Tap the heart icon on any wallpaper detail to save it here.")
            )
        } else {
            let wallpapers = favorites.map(\.asWallpaper)
            GridView(
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
    }

    // MARK: - Collections

    @ViewBuilder
    private var collectionsContent: some View {
        if collectionsVM.isLoading {
            LoadingView()
        } else if collectionsVM.needsAPIKey {
            ContentUnavailableView(
                "API Key Required",
                systemImage: "key",
                description: Text("Set your Wallhaven API Key in Settings to view collections.")
            )
        } else if let error = collectionsVM.error {
            ErrorView(message: error.localizedDescription) {
                Task { await collectionsVM.loadCollections() }
            }
        } else if collectionsVM.collections.isEmpty {
            ContentUnavailableView(
                "No Collections",
                systemImage: "folder",
                description: Text("No collections found for this account.")
            )
        } else {
            collectionsList
        }
    }

    private var collectionsList: some View {
        List {
            ForEach(collectionsVM.collections) { collection in
                NavigationLink {
                    CollectionWallpapersView(collection: collection)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "folder.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(collection.label)
                                .fontWeight(.medium)
                            Label("\(collection.count) wallpapers", systemImage: "photo.on.rectangle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if collection.isPublic == 1 {
                            Label("Public", systemImage: "globe")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Label("Private", systemImage: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Collection Wallpapers

private struct CollectionWallpapersView: View {
    let collection: WHCollection

    @State private var wallpapers: [Wallpaper] = []
    @State private var currentPage = 1
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var hasMore = true
    @State private var error: Error?
    @State private var selectedWallpaper: Wallpaper?

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(message: error.localizedDescription) {
                    Task { await loadFirstPage() }
                }
            } else if wallpapers.isEmpty {
                ContentUnavailableView(
                    "Empty Collection",
                    systemImage: "folder",
                    description: Text("No wallpapers in this collection.")
                )
            } else {
                GridView(
                    wallpapers: wallpapers,
                    isLoadingMore: isLoadingMore,
                    onLoadMore: { Task { await loadMore() } },
                    onSelect: { selectedWallpaper = $0 }
                )
            }
        }
        .navigationTitle(collection.label)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadFirstPage() }
        .navigationDestination(item: $selectedWallpaper) { wallpaper in
            if let index = wallpapers.firstIndex(where: { $0.id == wallpaper.id }),
               wallpapers.indices.contains(index)
            {
                DetailView(wallpapers: wallpapers, startIndex: index)
            }
        }
    }

    private func loadFirstPage() async {
        isLoading = true
        error = nil
        currentPage = 1
        hasMore = true
        do {
            let response = try await WallhavenFetch.shared.collectionWallpapers(
                collectionId: collection.id,
                page: 1
            )
            wallpapers = response.data
            hasMore = response.meta.hasNextPage
        } catch {
            self.error = error
        }
        isLoading = false
    }

    private func loadMore() async {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        let nextPage = currentPage + 1
        do {
            let response = try await WallhavenFetch.shared.collectionWallpapers(
                collectionId: collection.id,
                page: nextPage
            )
            wallpapers += response.data
            hasMore = response.meta.hasNextPage
            currentPage = nextPage
        } catch {
            // silently fail pagination
        }
        isLoadingMore = false
    }
}
