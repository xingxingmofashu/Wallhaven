import SwiftUI

// MARK: - Collections List

struct CollectionsView: View {
    @State private var viewModel = CollectionsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.hasUsername {
                    ContentUnavailableView(
                        "Username Not Set",
                        systemImage: "person.crop.circle.badge.questionmark",
                        description: Text("Set your wallhaven.cc username in Settings to view collections.")
                    )
                } else if viewModel.isLoading {
                    LoadingView()
                } else if let error = viewModel.error {
                    ErrorView(message: error.localizedDescription) {
                        Task { await viewModel.loadCollections() }
                    }
                } else if viewModel.collections.isEmpty {
                    ContentUnavailableView(
                        "No Collections",
                        systemImage: "folder",
                        description: Text("No collections found for this account.")
                    )
                } else {
                    collectionsList
                }
            }
            .navigationTitle("Collections")
            .task {
                if viewModel.hasUsername {
                    await viewModel.loadCollections()
                }
            }
        }
    }

    private var collectionsList: some View {
        List {
            ForEach(viewModel.collections) { collection in
                NavigationLink {
                    CollectionWallpapersView(
                        collection: collection,
                        username: viewModel.username
                    )
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
    }
}

// MARK: - Collection Wallpapers

private struct CollectionWallpapersView: View {
    let collection: WHCollection
    let username: String

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
                username: username,
                collectionId: collection.id,
                page: 1
            )
            wallpapers = response.data
            hasMore = response.meta.hasNextPage
            currentPage = 1
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
                username: username,
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
