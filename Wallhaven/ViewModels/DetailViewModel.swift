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

    // MARK: - Init

    init(wallpaper: Wallpaper) {
        self.wallpaper = wallpaper
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

    // MARK: - Favorites

    func refreshFavoriteStatus(in context: ModelContext) {
        let descriptor = FetchDescriptor<FavoriteWallpaper>(
            predicate: #Predicate { $0.wallpaperID == wallpaper.id }
        )
        isFavorited = (try? context.fetchCount(descriptor)) ?? 0 > 0
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
        } else {
            let favoriteWallpaper = FavoriteWallpaper(from: wallpaper)
            context.insert(favoriteWallpaper)
            try? context.save()
            isFavorited = true
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
                guard let image = UIImage(data: data) else {
                    return
                }

                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                guard status == .authorized || status == .limited else {
                    return
                }

                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
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
            ("Resolution", wallpaper.resolution),
            ("Ratio",      wallpaper.ratio),
            ("Type",       wallpaper.fileType),
            ("Size",       wallpaper.formattedFileSize),
            ("Purity",     wallpaper.purity.uppercased()),
            ("Category",   wallpaper.category.capitalized),
            ("Views",      "\(wallpaper.views)"),
            ("Favorites",  "\(wallpaper.favorites)"),
            ("Uploaded",   wallpaper.createdAt),
        ]
    }
}
