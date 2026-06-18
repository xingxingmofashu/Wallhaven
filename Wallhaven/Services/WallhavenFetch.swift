import Foundation

// MARK: - WallhavenFetch

actor WallhavenFetch {

    static let shared = WallhavenFetch()

    private var baseURL: String {
        UserDefaults.standard.string(forKey: "wallhaven_api_base_url")
            ?? "https://wallhaven.cc/api/v1"
    }
    private let session: URLSession

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

    func search(filters: SearchFilters, page: Int = 1) async throws -> SearchResponse {
        var items = filters.queryItems(page: page)
        if let key = apiKey {
            items.append(URLQueryItem(name: "apikey", value: key))
        }
        let url = try buildURL(path: "/search", queryItems: items)
        return try await fetch(url: url)
    }

    // MARK: - Related Wallpapers

    func relatedWallpapers(id: String, page: Int = 1) async throws -> SearchResponse {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "q", value: "like:\(id)"),
            URLQueryItem(name: "page", value: "\(page)")
        ]
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

    // MARK: - User Settings

    func userSettings() async throws -> UserSettings {
        var items: [URLQueryItem] = []
        if let key = apiKey {
            items.append(URLQueryItem(name: "apikey", value: key))
        }
        let url = try buildURL(path: "/settings", queryItems: items)
        let response: UserSettingsResponse = try await fetch(url: url)
        return response.data
    }

    // MARK: - Collections

    func collections() async throws -> [WHCollection] {
        var items: [URLQueryItem] = []
        if let key = apiKey {
            items.append(URLQueryItem(name: "apikey", value: key))
        }
        let url = try buildURL(path: "/collections", queryItems: items)
        let response: CollectionsResponse = try await fetch(url: url)
        return response.data
    }

    func collectionWallpapers(collectionId: Int, page: Int = 1) async throws -> SearchResponse {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)")
        ]
        if let key = apiKey {
            items.append(URLQueryItem(name: "apikey", value: key))
        }
        let url = try buildURL(path: "/collections/\(collectionId)", queryItems: items)
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
