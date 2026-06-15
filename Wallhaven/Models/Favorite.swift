import Foundation
import SwiftData

/// SwiftData persisted local favorite wallpaper
@Model
final class FavoriteWallpaper {
    @Attribute(.unique) var wallpaperID: String
    var addedAt: Date

    // Cache essential fields for offline display
    var thumbURL: String
    var fullPath: String
    var resolution: String
    var purity: String
    var category: String
    var ratio: String
    var fileType: String
    var colors: [String]

    init(from wallpaper: Wallpaper) {
        self.wallpaperID = wallpaper.id
        self.addedAt     = Date()
        self.thumbURL    = wallpaper.thumbs.large
        self.fullPath    = wallpaper.path
        self.resolution  = wallpaper.resolution
        self.purity      = wallpaper.purity
        self.category    = wallpaper.category
        self.ratio       = wallpaper.ratio
        self.fileType    = wallpaper.fileType
        self.colors      = wallpaper.colors
    }

    var thumbnailURL: URL? { URL(string: thumbURL) }

    /// Convert back to Wallpaper for reuse with WallpaperCell
    var asWallpaper: Wallpaper {
        Wallpaper(
            id: wallpaperID,
            url: "https://wallhaven.cc/w/\(wallpaperID)",
            shortURL: "",
            uploader: nil,
            views: 0,
            favorites: 0,
            source: "",
            purity: purity,
            category: category,
            dimensionX: 0,
            dimensionY: 0,
            resolution: resolution,
            ratio: ratio,
            fileSize: 0,
            fileType: fileType,
            createdAt: "",
            colors: colors,
            path: fullPath,
            thumbs: Thumbs(large: thumbURL, original: "", small: ""),
            tags: nil
        )
    }
}
