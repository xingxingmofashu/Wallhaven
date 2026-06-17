import SwiftUI
import Photos
import SwiftData

@Observable
@MainActor
final class DetailViewModel {

    // MARK: - State

    var wallpaper: Wallpaper
    var hasLoadedDetail = false
    var isLoadingDetail = false
    var isSavingToPhotos = false
    var isFavorited = false
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

    // MARK: - Related Wallpapers

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
        loadFavoriteStatuses(in: context)
    }

    func loadFavoriteStatuses(in context: ModelContext) {
        let allIDs = Set([wallpaper.id] + relatedWallpapers.map(\.id))
        guard !allIDs.isEmpty else { return }
        var descriptor = FetchDescriptor<FavoriteWallpaper>()
        descriptor.predicate = #Predicate { allIDs.contains($0.wallpaperID) }
        favoritedIDs = Set((try? context.fetch(descriptor))?.map(\.wallpaperID) ?? [])
    }

    func toggleFavorite(in context: ModelContext) {
        if isFavorited {
            let descriptor = FetchDescriptor<FavoriteWallpaper>(
                predicate: #Predicate { $0.wallpaperID == wallpaper.id }
            )
            if let favoriteWallpaper = try? context.fetch(descriptor).first {
                context.delete(favoriteWallpaper)
                try? context.save()
            }
            isFavorited = false
            favoritedIDs.remove(wallpaper.id)
        } else {
            let favoriteWallpaper = FavoriteWallpaper(from: wallpaper)
            context.insert(favoriteWallpaper)
            try? context.save()
            isFavorited = true
            favoritedIDs.insert(wallpaper.id)
        }
    }

    // MARK: - Save to Photos

    func saveToPhotos() {
        guard let url = wallpaper.fullURL else {
            return
        }
        isSavingToPhotos = true

        Task {
            defer { isSavingToPhotos = false }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)

                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                guard status == .authorized || status == .limited else {
                    return
                }

                try await PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: data, options: nil)
                }
            } catch {
                return
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
