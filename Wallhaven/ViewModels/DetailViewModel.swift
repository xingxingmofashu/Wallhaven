import Observation
import OSLog
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

    // MARK: - Load Detail

    func loadDetailIfNeeded() {
        guard !hasLoadedDetail, !isLoadingDetail else { return }
        isLoadingDetail = true
        Task {
            defer { isLoadingDetail = false }
            do {
                let wallpaperDetail = try await WallhavenFetch.shared.wallpaper(id: wallpaper.id)
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
        isLoadingRelated = true
        Task {
            defer { isLoadingRelated = false }
            do {
                let response = try await WallhavenFetch.shared.relatedWallpapers(id: wallpaper.id)
                relatedWallpapers = response.data
            } catch {
                // Silently handle load failure
            }
        }
    }

    func selectRelated(_ wallpaper: Wallpaper) {
        self.wallpaper = wallpaper
        hasLoadedDetail = false
        isLoadingDetail = false
        isFavorited = favoritedIDs.contains(wallpaper.id)
        loadDetailIfNeeded()
    }

    func refreshFavoriteStatus(in context: ModelContext) {
        let descriptor = FetchDescriptor<FavoriteWallpaper>(
            predicate: #Predicate { $0.wallpaperID == wallpaper.id }
        )
        isFavorited = (try? context.fetchCount(descriptor)) ?? 0 > 0
        refreshCollectionStatus(in: context)
        loadFavoriteStatuses(in: context)
    }

    func refreshCollectionStatus(in context: ModelContext) {
        let descriptor = FetchDescriptor<CollectionItem>(
            predicate: #Predicate { $0.wallpaperID == wallpaper.id }
        )
        isInCollection = (try? context.fetchCount(descriptor)) ?? 0 > 0
    }

    func loadFavoriteStatuses(in context: ModelContext) {
        let allIDs = Set([wallpaper.id] + relatedWallpapers.map(\.id))
        guard !allIDs.isEmpty else { return }
        var descriptor = FetchDescriptor<FavoriteWallpaper>()
        descriptor.predicate = #Predicate { allIDs.contains($0.wallpaperID) }
        favoritedIDs = Set((try? context.fetch(descriptor))?.map(\.wallpaperID) ?? [])
    }

    private let logger = Logger(subsystem: "com.wallhaven.app", category: "detail")

    func toggleFavorite(in context: ModelContext) {
        if isFavorited {
            let descriptor = FetchDescriptor<FavoriteWallpaper>(
                predicate: #Predicate { $0.wallpaperID == wallpaper.id }
            )
            if let favoriteWallpaper = try? context.fetch(descriptor).first {
                context.delete(favoriteWallpaper)
                do { try context.save() } catch { logger.error("delete favorite: \(error.localizedDescription)") }
            }
            isFavorited = false
            favoritedIDs.remove(wallpaper.id)
        } else {
            let favoriteWallpaper = FavoriteWallpaper(from: wallpaper)
            context.insert(favoriteWallpaper)
            do { try context.save() } catch { logger.error("save favorite: \(error.localizedDescription)") }
            isFavorited = true
            favoritedIDs.insert(wallpaper.id)
        }
    }

    // MARK: - Download Progress

    var downloadingIDs: Set<String> = []

    var isDownloading: Bool {
        downloadingIDs.contains(wallpaper.id)
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
                guard status == .authorized || status == .limited else { return }

                try await PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: data, options: nil)
                }

                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } catch {
                notificationFeedback(.error)
            }
        }
    }

    // MARK: - Share

    var shareItems: [Any] {
        [wallpaper.url]
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


