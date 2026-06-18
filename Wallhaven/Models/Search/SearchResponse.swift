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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentPage = try container.decode(Int.self, forKey: .currentPage)
        lastPage    = try container.decode(Int.self, forKey: .lastPage)
        perPage     = try container.decode(LenientInt.self, forKey: .perPage).value
        total       = try container.decode(Int.self, forKey: .total)
        query       = try container.decodeIfPresent(QueryValue.self, forKey: .query)
        seed        = try container.decodeIfPresent(String.self, forKey: .seed)
    }

    var hasNextPage: Bool { currentPage < lastPage }
}

private struct LenientInt: Decodable {
    let value: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else {
            let stringValue = try container.decode(String.self)
            guard let intValue = Int(stringValue) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Expected Int or numeric String, got '\(stringValue)'"
                )
            }
            value = intValue
        }
    }
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
        case .string(let queryString):
            try container.encode(queryString)
        case .tag(let tagID, let tagName):
            try container.encode(TagQuery(id: tagID, tag: tagName))
        }
    }
}

private struct TagQuery: Codable {
    let id: Int
    let tag: String
}
