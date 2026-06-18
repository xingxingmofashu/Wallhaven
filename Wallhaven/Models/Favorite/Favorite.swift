import Foundation
import SwiftData

/// SwiftData persisted local favorite wallpaper
@Model
final class FavoriteWallpaper: StoredWallpaper {
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
    var dimensionX: Int
    var dimensionY: Int

    init(from wallpaper: Wallpaper) {
        self.wallpaperID = wallpaper.id
        self.addedAt     = Date()
        self.thumbURL    = wallpaper.thumbnails.large
        self.fullPath    = wallpaper.path
        self.resolution  = wallpaper.resolution
        self.purity      = wallpaper.purity
        self.category    = wallpaper.category
        self.ratio       = wallpaper.ratio
        self.fileType    = wallpaper.fileType
        self.colors      = wallpaper.colors
        self.dimensionX  = wallpaper.dimensionX
        self.dimensionY  = wallpaper.dimensionY
    }
}
