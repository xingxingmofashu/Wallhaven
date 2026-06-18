import SwiftUI
import SwiftData

struct DetailView: View {
    @State private var viewModel: DetailViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationState.self) private var navigationState
    @Query(sort: \WallhavenCollection.sortOrder)
    private var collections: [WallhavenCollection]
    @State private var showShareSheet = false
    @State private var showInfoSheet = false
    @State private var showCollectionPicker = false
    @State private var scrollPosition: Int?
    @State private var wallpapers: [Wallpaper]
    @State private var selectedIndex: Int

    private var currentID: String? { wallpapers.indices.contains(selectedIndex) ? wallpapers[selectedIndex].id : nil }

    private var currentWallpaper: Wallpaper {
        wallpapers.indices.contains(selectedIndex) ? wallpapers[selectedIndex] : wallpapers[0]
    }

    init(wallpaper: Wallpaper, relatedWallpapers: [Wallpaper] = []) {
        _viewModel = State(initialValue: DetailViewModel(wallpaper: wallpaper, relatedWallpapers: relatedWallpapers))
        _wallpapers = State(initialValue: [wallpaper])
        _selectedIndex = State(initialValue: 0)
        _scrollPosition = State(initialValue: 0)
    }

    init(wallpapers: [Wallpaper], startIndex: Int) {
        let wallpaper = wallpapers[startIndex]
        _viewModel = State(initialValue: DetailViewModel(wallpaper: wallpaper, relatedWallpapers: wallpapers))
        _wallpapers = State(initialValue: wallpapers)
        _selectedIndex = State(initialValue: startIndex)
        _scrollPosition = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(Array(wallpapers.enumerated()), id: \.element.id) { index, wallpaper in
                            imageView(for: wallpaper)
                                .containerRelativeFrame(.horizontal)
                                .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $scrollPosition)

                DetailThumbnailView(
                    relatedWallpapers: viewModel.relatedWallpapers,
                    currentID: currentID,
                    favoritedIDs: viewModel.favoritedIDs,
                    selectedIndex: selectedIndex,
                    onSelect: { wallpaper in
                        if let idx = wallpapers.firstIndex(where: { $0.id == wallpaper.id }) {
                            scrollPosition = idx
                        } else {
                            wallpapers = [wallpaper]
                            scrollPosition = 0
                            viewModel.selectRelated(wallpaper)
                        }
                    }
                )
                    .frame(height: 44)
                    .opacity(viewModel.relatedWallpapers.isEmpty ? 0 : 1)
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let vertical = value.translation.height
                    let horizontal = value.translation.width
                    if vertical > 80 && abs(horizontal) < abs(vertical) {
                        dismiss()
                    }
                }
        )
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            DetailTopToolbar(
                onDismiss: { dismiss() },
                wallpaperURL: viewModel.wallpaper.url
            )
            DetailBottomToolbar(
                isFavorited: viewModel.isFavorited,
                isInCollection: viewModel.isInCollection,
                onShare: { showShareSheet = true },
                onToggleFavorite: { viewModel.toggleFavorite(in: modelContext) },
                onInfo: { showInfoSheet = true },
                onAddToCollection: handleAddToCollection,
                onSaveToPhotos: { viewModel.saveToPhotos() }
            )
        }
        .onChange(of: scrollPosition) { _, newValue in
            guard let index = newValue, wallpapers.indices.contains(index), index != selectedIndex else { return }
            selectedIndex = index
            viewModel.selectRelated(wallpapers[index])
            preloadAdjacent(at: index)
        }
        .task {
            viewModel.refreshFavoriteStatus(in: modelContext)
            viewModel.loadDetailIfNeeded()
            viewModel.loadRelatedWallpapers()
            preloadAdjacent(at: selectedIndex)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: viewModel.shareItems)
        }
        .sheet(isPresented: $showInfoSheet) {
            DetailInfoSheetView(
                wallpaper: viewModel.wallpaper,
                formattedInfo: viewModel.formattedInfo,
                tags: viewModel.wallpaper.tags ?? [],
                onSearchTag: { tag in
                    dismiss()
                    navigationState.searchTag(tag)
                },
                onDone: { showInfoSheet = false }
            )
        }
        .sheet(isPresented: $showCollectionPicker) {
            CollectionPickerSheet(
                collections: collections,
                onSelect: { collectionID in
                    addToCollection(collectionID: collectionID)
                    showCollectionPicker = false
                },
                onCreateNew: { name in
                    let newCollection = WallhavenCollection(name: name)
                    modelContext.insert(newCollection)
                    try? modelContext.save()
                    addToCollection(collectionID: newCollection.id)
                    showCollectionPicker = false
                }
            )
        }
    }

    // MARK: - Collection Logic

    private func handleAddToCollection() {
        let wallpaperID = currentWallpaper.id
        if viewModel.isInCollection {
            let descriptor = FetchDescriptor<CollectionItem>(
                predicate: #Predicate { $0.wallpaperID == wallpaperID }
            )
            if let item = try? modelContext.fetch(descriptor).first {
                modelContext.delete(item)
                try? modelContext.save()
            }
            viewModel.isInCollection = false
        } else {
            if collections.isEmpty {
                let defaultCollection = WallhavenCollection(name: "Default")
                modelContext.insert(defaultCollection)
                try? modelContext.save()
                addToCollection(collectionID: defaultCollection.id)
            } else if collections.count == 1 {
                addToCollection(collectionID: collections[0].id)
            } else {
                showCollectionPicker = true
            }
        }
    }

    private func addToCollection(collectionID: UUID) {
        let item = CollectionItem(from: currentWallpaper, collectionID: collectionID)
        modelContext.insert(item)
        try? modelContext.save()
        viewModel.isInCollection = true
    }

    // MARK: - Image View

    private func preloadAdjacent(at index: Int) {
        for offset in [-1, 1] {
            let target = index + offset
            if wallpapers.indices.contains(target), let url = wallpapers[target].fullURL {
                CacheImage.shared.preload(url: url)
            }
        }
    }

    private func imageView(for wallpaper: Wallpaper) -> some View {
        CacheAsyncImage(url: wallpaper.fullURL) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            CacheAsyncImage(url: wallpaper.thumbnailURL) { thumb in
                thumb
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 20, opaque: true)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
            }
            .aspectRatio(wallpaper.aspectRatio, contentMode: .fit)
            .clipShape(Rectangle())
        }
    }

}

// MARK: - Collection Picker Sheet

struct CollectionPickerSheet: View {
    let collections: [WallhavenCollection]
    let onSelect: (UUID) -> Void
    let onCreateNew: (String) -> Void

    @State private var showCreateField = false
    @State private var newName = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(collections) { collection in
                    Button {
                        onSelect(collection.id)
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                            Text(collection.name)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }

                if showCreateField {
                    HStack {
                        TextField("Collection name", text: $newName)
                        Button("Save") {
                            let name = newName.trimmingCharacters(in: .whitespaces)
                            if !name.isEmpty {
                                onCreateNew(name)
                            }
                        }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } else {
                    Button {
                        showCreateField = true
                    } label: {
                        Label("New Collection", systemImage: "folder.badge.plus")
                    }
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
