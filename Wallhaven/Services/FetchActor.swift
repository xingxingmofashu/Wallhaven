import Foundation

// MARK: - FetchActor

actor FetchActor {

    static let shared = FetchActor()

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
        let items = filters.queryItems(page: page)
        let url = try buildURL(path: "/search", queryItems: items)
        return try await fetch(url: url)
    }

    // MARK: - Wallpaper Detail

    func getWallpaperDetail(id: String) async throws -> Wallpaper {
        let url = try buildURL(path: "/w/\(id)")
        let response: WallpaperDetailResponse = try await fetch(url: url)
        return response.data
    }

    // MARK: - User Settings

    func getUserSettings() async throws -> UserSettings {
        let url = try buildURL(path: "/settings")
        let response: UserSettingsResponse = try await fetch(url: url)
        return response.data
    }

    // MARK: - Private Helpers

    private func buildURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        var items = queryItems
        if let key = apiKey {
            items.append(URLQueryItem(name: "apikey", value: key))
        }
        guard var comps = URLComponents(string: baseURL + path) else {
            throw FetchError.invalidURL
        }
        if !items.isEmpty {
            comps.queryItems = items
        }
        guard let url = comps.url else {
            throw FetchError.invalidURL
        }
        return url
    }

    private func fetch<T: Decodable>(url: URL) async throws -> T {
        try Task.checkCancellation()
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw FetchError.networkError(error)
        }
        try Task.checkCancellation()

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200...299: break
            case 401: throw FetchError.unauthorized
            case 429: throw FetchError.rateLimited
            default:  throw FetchError.serverError(http.statusCode)
            }
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw FetchError.decodingError(error)
        }
    }
}

// MARK: - FetchError

enum FetchError: LocalizedError {
    case invalidURL
    case unauthorized
    case rateLimited
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("error.invalid_url", comment: "")
        case .unauthorized:
            return NSLocalizedString("error.unauthorized", comment: "")
        case .rateLimited:
            return NSLocalizedString("error.rate_limited", comment: "")
        case .serverError(let statusCode):
            return String(
                format: NSLocalizedString("error.server", comment: ""),
                statusCode
            )
        case .decodingError(let underlyingError):
            return String(
                format: NSLocalizedString("error.decoding", comment: ""),
                underlyingError.localizedDescription
            )
        case .networkError(let underlyingError):
            return String(
                format: NSLocalizedString("error.network", comment: ""),
                underlyingError.localizedDescription
            )
        }
    }
}
