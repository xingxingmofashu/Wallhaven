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

    // Thumbnail URL, prefer large, fallback to original
    var thumbnailURL: URL? { URL(string: thumbs.large) }
    var fullURL: URL?      { URL(string: path) }
    var pageURL: URL?      { URL(string: url) }

    // Compute aspect ratio to determine if portrait
    var aspectRatio: Double {
        guard dimensionY > 0 else { return 1 }
        return Double(dimensionX) / Double(dimensionY)
    }
    var isPortrait: Bool { aspectRatio < 1.0 }

    // Format file size
    var formattedFileSize: String {
        let mb = Double(fileSize) / 1_048_576
        return String(format: "%.1f MB", mb)
    }
}

// MARK: - Uploader

struct Uploader: Codable, Hashable {
    let username: String
    let group: String
    let avatar: Avatar?
}

struct Avatar: Codable, Hashable {
    let px200: String?
    let px128: String?
    let px32:  String?
    let px20:  String?

    enum CodingKeys: String, CodingKey {
        case px200 = "200px"
        case px128 = "128px"
        case px32  = "32px"
        case px20  = "20px"
    }
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

// MARK: - Search Response

struct SearchResponse: Codable {
    let data: [Wallpaper]
    let meta: Meta
}

struct Meta: Codable {
    let currentPage: Int
    let lastPage: Int
    let perPage: Int
    let total: Int
    let query: QueryValue?
    let seed: String?

    enum CodingKeys: String, CodingKey {
        case total, query, seed
        case currentPage = "current_page"
        case lastPage    = "last_page"
        case perPage     = "per_page"
    }

    var hasNextPage: Bool { currentPage < lastPage }
}

// query field may be a String or {id, tag} object
enum QueryValue: Codable, Hashable {
    case string(String)
    case tag(id: Int, tag: String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .string(str)
        } else {
            let obj = try container.decode(TagQuery.self)
            self = .tag(id: obj.id, tag: obj.tag)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s):
            try container.encode(s)
        case .tag(let id, let tag):
            try container.encode(TagQuery(id: id, tag: tag))
        }
    }
}

private struct TagQuery: Codable {
    let id: Int
    let tag: String
}

// MARK: - Wallpaper Detail Response

struct WallpaperDetailResponse: Codable {
    let data: Wallpaper
}

// MARK: - Tag Detail Response

struct TagDetailResponse: Codable {
    let data: Tag
}

// MARK: - User Settings

struct UserSettings: Codable {
    let thumbSize: String
    let perPage: String
    let purity: [String]
    let categories: [String]
    let resolutions: [String]
    let aspectRatios: [String]
    let toplistRange: String
    let tagBlacklist: [String]
    let userBlacklist: [String]

    enum CodingKeys: String, CodingKey {
        case purity, categories, resolutions
        case thumbSize     = "thumb_size"
        case perPage       = "per_page"
        case aspectRatios  = "aspect_ratios"
        case toplistRange  = "toplist_range"
        case tagBlacklist  = "tag_blacklist"
        case userBlacklist = "user_blacklist"
    }
}

struct UserSettingsResponse: Codable {
    let data: UserSettings
}

// MARK: - Collection

struct Collection: Codable, Identifiable, Hashable {
    let id: Int
    let label: String
    let views: Int
    let `public`: Int
    let count: Int

    var isPublic: Bool { `public` == 1 }
}

struct CollectionsResponse: Codable {
    let data: [Collection]
}
