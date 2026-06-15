import Foundation

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
