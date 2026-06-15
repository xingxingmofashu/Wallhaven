import SwiftUI
import Photos

@Observable
@MainActor
final class WallpaperDetailViewModel {

    // MARK: - State

    var wallpaper: Wallpaper
    var detailLoaded  = false          // Whether full details with tags have been loaded
    var isLoadingDetail = false
    var isSaving      = false          // Saving to photo album
    var saveResult: SaveResult?

    enum SaveResult: Equatable {
        case success
        case failure(String)
    }

    // MARK: - Init

    init(wallpaper: Wallpaper) {
        self.wallpaper = wallpaper
    }

    // MARK: - Load Detail (fetch full data with tags)

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
                // Download original image
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    saveResult = .failure("Invalid image data")
                    return
                }

                // Request photo library permission
                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                guard status == .authorized || status == .limited else {
                    saveResult = .failure("Photo library permission required, please enable in Settings")
                    return
                }

                // Save
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
