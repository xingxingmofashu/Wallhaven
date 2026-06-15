import SwiftUI
import Photos
import SwiftData

@Observable
@MainActor
final class WallpaperDetailViewModel {

    // MARK: - State

    var wallpaper: Wallpaper
    var detailLoaded    = false
    var isLoadingDetail = false
    var isSaving        = false
    var saveResult: SaveResult?
    var isFavorited     = false
    var favoriteToast: FavoriteToast?

    enum SaveResult: Equatable {
        case success
        case failure(String)
    }

    enum FavoriteToast: Equatable {
        case added, removed

        var message: String {
            switch self {
            case .added:   return "Added to favorites"
            case .removed: return "Removed from favorites"
            }
        }
    }

    // MARK: - Init

    init(wallpaper: Wallpaper) {
        self.wallpaper = wallpaper
    }

    // MARK: - Load Detail

    func loadDetailIfNeeded() {
        guard !detailLoaded, !isLoadingDetail else { return }
        isLoadingDetail = true
        Task {
            defer { isLoadingDetail = false }
            do {
                let full = try await WallhavenFetch.shared.wallpaper(id: wallpaper.id)
                wallpaper    = full
                detailLoaded = true
            } catch {
                // Silently handle load failure, keep preview data
            }
        }
    }

    // MARK: - Favorites

    func checkFavoriteStatus(in context: ModelContext) {
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
            if let fav = try? context.fetch(descriptor).first {
                context.delete(fav)
                try? context.save()
            }
            isFavorited = false
            favoriteToast = .removed
        } else {
            let fav = FavoriteWallpaper(from: wallpaper)
            context.insert(fav)
            try? context.save()
            isFavorited = true
            favoriteToast = .added
        }
    }

    // MARK: - Save to Photos

    func saveToPhotos() {
        guard let url = wallpaper.fullURL else {
            saveResult = .failure("Invalid image URL")
            return
        }
        isSaving = true
        saveResult = nil

        Task {
            defer { isSaving = false }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    saveResult = .failure("Invalid image data")
                    return
                }

                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                guard status == .authorized || status == .limited else {
                    saveResult = .failure("Photo library permission required, please enable in Settings")
                    return
                }

                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
                saveResult = .success
            } catch {
                saveResult = .failure("Save failed: \(error.localizedDescription)")
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
