import Photos
import SwiftData
import UIKit

@Observable
@MainActor
final class DetailViewModel {

    // MARK: - State

    var wallpaper: Wallpaper
    var hasLoadedDetail = false
    var isLoadingDetail = false
    var isFavorited = false
    var isInCollection = false
    var favoritedIDs: Set<String> = []

    // MARK: - Related Wallpapers

    var relatedWallpapers: [Wallpaper] = []
    var isLoadingRelated = false

    // MARK: - Init

    init(wallpaper: Wallpaper, relatedWallpapers: [Wallpaper] = []) {
        self.wallpaper = wallpaper
        self.relatedWallpapers = relatedWallpapers
    }

    // MARK: - Tasks

    private var detailTask: Task<Void, Never>?

    // MARK: - Load Detail

    func loadDetailIfNeeded() {
        guard !hasLoadedDetail, !isLoadingDetail else { return }
        detailTask?.cancel()
        isLoadingDetail = true
        detailTask = Task {
            defer { isLoadingDetail = false }
            do {
                let wallpaperDetail = try await FetchActor.shared.getWallpaperDetail(id: wallpaper.id)
                wallpaper = wallpaperDetail
                hasLoadedDetail = true
            } catch {
                // Silently handle load failure, keep preview data
            }
        }
    }

    // MARK: - Related Wallpapers Actions

    func loadRelatedWallpapers() {
        guard !isLoadingRelated, relatedWallpapers.isEmpty else { return }
        detailTask?.cancel()
        isLoadingRelated = true
        detailTask = Task {
            defer { isLoadingRelated = false }
            do {
                var relatedFilters = SearchFilters()
                relatedFilters.query = "like:\(wallpaper.id)"
                let response = try await FetchActor.shared.search(filters: relatedFilters)
                relatedWallpapers = response.data
            } catch {
                // Silently handle load failure
            }
        }
    }

    func selectRelated(_ wallpaper: Wallpaper) {
        detailTask?.cancel()
        self.wallpaper = wallpaper
        hasLoadedDetail = false
        isLoadingDetail = false
        isFavorited = favoritedIDs.contains(wallpaper.id)
        loadDetailIfNeeded()
    }

    func refreshFavoriteStatus(in context: ModelContext) {
        let descriptor = FetchDescriptor<StoredWallpaper>(
            predicate: #Predicate { $0.wallpaperID == wallpaper.id && $0.collectionID == nil }
        )
        isFavorited = (try? context.fetchCount(descriptor)) ?? 0 > 0
        refreshCollectionStatus(in: context)
        loadFavoriteStatuses(in: context)
    }

    func refreshCollectionStatus(in context: ModelContext) {
        let descriptor = FetchDescriptor<StoredWallpaper>(
            predicate: #Predicate { $0.wallpaperID == wallpaper.id && $0.collectionID != nil }
        )
        isInCollection = (try? context.fetchCount(descriptor)) ?? 0 > 0
    }

    func loadFavoriteStatuses(in context: ModelContext) {
        let allIDs = Set([wallpaper.id] + relatedWallpapers.map(\.id))
        guard !allIDs.isEmpty else { return }
        var descriptor = FetchDescriptor<StoredWallpaper>(
            predicate: #Predicate { allIDs.contains($0.wallpaperID) && $0.collectionID == nil }
        )
        favoritedIDs = Set((try? context.fetch(descriptor))?.map(\.wallpaperID) ?? [])
    }

    func handleAddToCollection(in context: ModelContext, collections: [CollectionFolder]) {
        let wallpaperID = wallpaper.id
        if isInCollection {
            let descriptor = FetchDescriptor<StoredWallpaper>(
                predicate: #Predicate { $0.wallpaperID == wallpaperID && $0.collectionID != nil }
            )
            if let item = try? context.fetch(descriptor).first {
                context.delete(item)
                context.saveWithLog()
            }
            isInCollection = false
        } else {
            if collections.isEmpty {
                let defaultCollection = CollectionFolder(name: "Default")
                context.insert(defaultCollection)
                context.saveWithLog()
                addToCollection(collectionID: defaultCollection.id, in: context)
            } else if collections.count == 1 {
                addToCollection(collectionID: collections[0].id, in: context)
            } else {
                showCollectionPicker = true
            }
        }
    }

    private func addToCollection(collectionID: UUID, in context: ModelContext) {
        let item = StoredWallpaper(from: wallpaper, collectionID: collectionID)
        context.insert(item)
        context.saveWithLog()
        isInCollection = true
    }

    var showCollectionPicker = false

    func addToSpecificCollection(_ collectionID: UUID, in context: ModelContext) {
        addToCollection(collectionID: collectionID, in: context)
        showCollectionPicker = false
    }

    func toggleFavorite(in context: ModelContext) {
        if isFavorited {
            let descriptor = FetchDescriptor<StoredWallpaper>(
                predicate: #Predicate { $0.wallpaperID == wallpaper.id && $0.collectionID == nil }
            )
            if let favoriteWallpaper = try? context.fetch(descriptor).first {
                context.delete(favoriteWallpaper)
                context.saveWithLog()
            }
            isFavorited = false
            favoritedIDs.remove(wallpaper.id)
        } else {
            let favoriteWallpaper = StoredWallpaper(from: wallpaper)
            context.insert(favoriteWallpaper)
            context.saveWithLog()
            isFavorited = true
            favoritedIDs.insert(wallpaper.id)
        }
    }

    // MARK: - Download Progress

    var downloadingIDs: Set<String> = []

    var isDownloading: Bool {
        downloadingIDs.contains(wallpaper.id)
    }

    var saveResult: SaveResult?

    enum SaveResult {
        case success
        case error
    }

    // MARK: - Save to Photos

    func saveToPhotos() {
        guard let url = wallpaper.fullURL else { return }
        let wallpaperID = wallpaper.id

        downloadingIDs.insert(wallpaperID)

        Task {
            defer { downloadingIDs.remove(wallpaperID) }
            do {
                let data: Data
                if let cached = CacheImage.shared.data(for: url) {
                    data = cached
                } else if let cached = CacheImage.shared.image(for: url),
                          let imageData = cached.jpegData(compressionQuality: 1) ?? cached.pngData() {
                    data = imageData
                } else {
                    let (asyncBytes, response) = try await URLSession.shared.bytes(from: url)
                    let total = Int(response.expectedContentLength)
                    var buffer = Data()
                    buffer.reserveCapacity(total > 0 ? total : 0)
                    for try await byte in asyncBytes {
                        buffer.append(byte)
                    }
                    data = buffer
                    CacheImage.shared.insert(data: data, for: url)
                    if let image = UIImage(data: data) {
                        CacheImage.shared.insert(image, for: url)
                    }
                }

                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                guard status == .authorized || status == .limited else {
                    saveResult = .error
                    return
                }

                try await PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: data, options: nil)
                }

                saveResult = .success
            } catch {
                saveResult = .error
            }
        }
    }

    // MARK: - Share

    var shareItems: [URL] {
        [wallpaper.url].compactMap { URL(string: $0) }
    }

    // MARK: - Formatted Info

    var formattedInfo: [(label: String, value: String)] {
        [
            (NSLocalizedString("detail.info.resolution", comment: ""), wallpaper.resolution),
            (NSLocalizedString("detail.info.ratio", comment: ""), wallpaper.ratio),
            (NSLocalizedString("detail.info.type", comment: ""), wallpaper.fileType),
            (NSLocalizedString("detail.info.size", comment: ""), wallpaper.formattedFileSize),
            (NSLocalizedString("detail.info.purity", comment: ""), wallpaper.purity.uppercased()),
            (NSLocalizedString("detail.info.category", comment: ""), wallpaper.category.capitalized),
            (NSLocalizedString("detail.info.views", comment: ""), "\(wallpaper.views)"),
            (NSLocalizedString("detail.info.favorites", comment: ""), "\(wallpaper.favorites)"),
            (NSLocalizedString("detail.info.uploaded", comment: ""), wallpaper.createdAt),
        ]
    }
}


