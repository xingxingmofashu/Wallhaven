import Foundation

// MARK: - Wallpaper

struct Wallpaper: Codable, Identifiable, Hashable {
    let id: String
    let url: String
    let shortURL: String
    let uploader: Uploader?
    let views: Int
    let favorites: Int
    let source: String
    let purity: String
    let category: String
    let dimensionX: Int
    let dimensionY: Int
    let resolution: String
    let ratio: String
    let fileSize: Int
    let fileType: String
    let createdAt: String
    let colors: [String]
    let path: String
    let thumbs: Thumbs
    let tags: [Tag]?

    enum CodingKeys: String, CodingKey {
        case id, url, views, favorites, source, purity, category
        case resolution, ratio, colors, path, thumbs, tags
        case shortURL     = "short_url"
        case uploader
        case dimensionX   = "dimension_x"
        case dimensionY   = "dimension_y"
        case fileSize     = "file_size"
        case fileType     = "file_type"
        case createdAt    = "created_at"
    }

    var thumbnailURL: URL? { URL(string: thumbs.large) }
    var fullURL: URL?      { URL(string: path) }

    var aspectRatio: Double {
        guard dimensionY > 0 else { return 1 }
        return Double(dimensionX) / Double(dimensionY)
    }

    var formattedFileSize: String {
        let mb = Double(fileSize) / 1_048_576
        return String(format: "%.1f MB", mb)
    }
}

// MARK: - Uploader

struct Uploader: Codable, Hashable {
    let username: String
    let group: String
}

// MARK: - Thumbs

struct Thumbs: Codable, Hashable {
    let large:    String
    let original: String
    let small:    String
}

// MARK: - Tag

struct Tag: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let alias: String
    let categoryID: Int
    let category: String
    let purity: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, alias, category, purity
        case categoryID = "category_id"
        case createdAt  = "created_at"
    }
}

// MARK: - Preview Helper

extension Wallpaper {
    static let preview = Wallpaper(
        id: "94x38z",
        url: "https://wallhaven.cc/w/94x38z",
        shortURL: "http://whvn.cc/94x38z",
        uploader: nil,
        views: 1024,
        favorites: 42,
        source: "",
        purity: "sfw",
        category: "anime",
        dimensionX: 1920,
        dimensionY: 1080,
        resolution: "1920x1080",
        ratio: "1.78",
        fileSize: 2_048_000,
        fileType: "image/jpeg",
        createdAt: "2024-01-01 00:00:00",
        colors: ["#000000", "#ffffff"],
        path: "https://w.wallhaven.cc/full/94/wallhaven-94x38z.jpg",
        thumbs: Thumbs(
            large:    "https://th.wallhaven.cc/lg/94/94x38z.jpg",
            original: "https://th.wallhaven.cc/orig/94/94x38z.jpg",
            small:    "https://th.wallhaven.cc/small/94/94x38z.jpg"
        ),
        tags: nil
    )
}
