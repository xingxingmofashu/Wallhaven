import Foundation

// MARK: - API Errors

enum WallhavenError: LocalizedError {
    case invalidURL
    case unauthorized
    case rateLimited
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid request URL"
        case .unauthorized:         return "Invalid API key or unauthorized access"
        case .rateLimited:          return "Too many requests, please try again later (45 req/min limit)"
        case .serverError(let c):   return "Server error: \(c)"
        case .decodingError(let e): return "Failed to parse data: \(e.localizedDescription)"
        case .networkError(let e):  return "Network error: \(e.localizedDescription)"
        case .unknown:              return "Unknown error"
        }
    }
}

// MARK: - WallhavenAPI

actor WallhavenAPI {

    static let shared = WallhavenAPI()

    private let baseURL = "https://wallhaven.cc/api/v1"
    private let session: URLSession

    /// Read API key from UserDefaults
    private var apiKey: String? {
        let key = UserDefaults.standard.string(forKey: "wallhaven_api_key")
        return key?.isEmpty == false ? key : nil
    }

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Search

    /// Search / get list
    func search(filters: SearchFilters, page: Int = 1) async throws -> SearchResponse {
        var items = filters.queryItems(page: page)
        if let key = apiKey {
            items.append(URLQueryItem(name: "apikey", value: key))
        }
        let url = try buildURL(path: "/search", queryItems: items)
        return try await fetch(url: url)
    }

    // MARK: - Wallpaper Detail

    func wallpaper(id: String) async throws -> Wallpaper {
        var items: [URLQueryItem] = []
        if let key = apiKey {
            items.append(URLQueryItem(name: "apikey", value: key))
        }
        let url = try buildURL(path: "/w/\(id)", queryItems: items)
        let response: WallpaperDetailResponse = try await fetch(url: url)
        return response.data
    }

    // MARK: - Tag

    func tag(id: Int) async throws -> Tag {
        let url = try buildURL(path: "/tag/\(id)")
        let response: TagDetailResponse = try await fetch(url: url)
        return response.data
    }

    // MARK: - User Settings

    func userSettings() async throws -> UserSettings {
        guard let key = apiKey else { throw WallhavenError.unauthorized }
        let url = try buildURL(path: "/settings", queryItems: [
            URLQueryItem(name: "apikey", value: key)
        ])
        let response: UserSettingsResponse = try await fetch(url: url)
        return response.data
    }

    // MARK: - Collections

    /// Get current authenticated user's collection list
    func myCollections() async throws -> [Collection] {
        guard let key = apiKey else { throw WallhavenError.unauthorized }
        let url = try buildURL(path: "/collections", queryItems: [
            URLQueryItem(name: "apikey", value: key)
        ])
        let response: CollectionsResponse = try await fetch(url: url)
        return response.data
    }

    /// Get public collection list for a specific user
    func collections(username: String) async throws -> [Collection] {
        let url = try buildURL(path: "/collections/\(username)")
        let response: CollectionsResponse = try await fetch(url: url)
        return response.data
    }

    /// Get wallpaper list within a collection
    func collectionWallpapers(
        username: String,
        collectionID: Int,
        purity: String = "100",
        page: Int = 1
    ) async throws -> SearchResponse {
        var items = [
            URLQueryItem(name: "purity", value: purity),
            URLQueryItem(name: "page",   value: "\(page)")
        ]
        if let key = apiKey {
            items.append(URLQueryItem(name: "apikey", value: key))
        }
        let url = try buildURL(
            path: "/collections/\(username)/\(collectionID)",
            queryItems: items
        )
        return try await fetch(url: url)
    }

    // MARK: - Private Helpers

    private func buildURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        guard var comps = URLComponents(string: baseURL + path) else {
            throw WallhavenError.invalidURL
        }
        if !queryItems.isEmpty {
            comps.queryItems = queryItems
        }
        guard let url = comps.url else {
            throw WallhavenError.invalidURL
        }
        return url
    }

    private func fetch<T: Decodable>(url: URL) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw WallhavenError.networkError(error)
        }

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200...299: break
            case 401: throw WallhavenError.unauthorized
            case 429: throw WallhavenError.rateLimited
            default:  throw WallhavenError.serverError(http.statusCode)
            }
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw WallhavenError.decodingError(error)
        }
    }
}
