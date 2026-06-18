import Foundation

protocol StoredWallpaper: HasDimensions {
    var wallpaperID: String { get }
    var thumbURL: String { get }
    var fullPath: String { get }
    var resolution: String { get }
    var purity: String { get }
    var category: String { get }
    var ratio: String { get }
    var fileType: String { get }
    var colors: [String] { get }
    var dimensionX: Int { get }
    var dimensionY: Int { get }
}

extension StoredWallpaper {
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
            dimensionX: dimensionX,
            dimensionY: dimensionY,
            resolution: resolution,
            ratio: ratio,
            fileSize: 0,
            fileType: fileType,
            createdAt: "",
            colors: colors,
            path: fullPath,
            thumbnails: Thumbnails(large: thumbURL, original: "", small: ""),
            tags: nil
        )
    }
}
