import Foundation

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
