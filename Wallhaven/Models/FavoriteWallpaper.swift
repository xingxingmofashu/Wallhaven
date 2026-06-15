import Foundation
import SwiftData

/// SwiftData 持久化的本地收藏壁纸
@Model
final class FavoriteWallpaper {
    @Attribute(.unique) var wallpaperID: String
    var addedAt: Date

    // 缓存必要字段，离线也能显示
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
    var imageURL: URL?     { URL(string: fullPath) }
}
