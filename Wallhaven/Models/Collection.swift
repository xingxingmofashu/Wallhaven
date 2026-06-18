import Foundation

struct CollectionsResponse: Codable {
    let data: [WHCollection]
}

struct WHCollection: Codable, Identifiable, Hashable {
    let id: Int
    let label: String
    let views: Int
    let isPublic: Int
    let count: Int

    enum CodingKeys: String, CodingKey {
        case id, label, views, count
        case isPublic = "public"
    }
}
