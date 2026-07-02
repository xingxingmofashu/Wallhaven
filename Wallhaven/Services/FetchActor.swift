import Foundation

// MARK: - FetchActor

actor FetchActor {

    static let shared = FetchActor()
    static let defaultBaseURL = "https://wallhaven.cc/api/v1"

    private let session: URLSession

    // Cached to avoid reading UserDefaults on every request.
    private var cachedBaseURL: String
    private var cachedAPIKey: String?

    private var baseURL: String { cachedBaseURL }
    private var apiKey: String? { cachedAPIKey }

    private static let decoder: JSONDecoder = JSONDecoder()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity       = true
        self.session = URLSession(configuration: config)
        cachedBaseURL = Self.resolveBaseURL()
        cachedAPIKey  = Self.resolveAPIKey()
    }

    /// Call after the user changes the API key or base URL in Settings.
    func refreshConfiguration() {
        cachedBaseURL = Self.resolveBaseURL()
        cachedAPIKey  = Self.resolveAPIKey()
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
        let response: APIResponse<Wallpaper> = try await fetch(url: url)
        return response.data
    }

    // MARK: - User Settings

    func getUserSettings() async throws -> UserSettings {
        let url = try buildURL(path: "/settings")
        let response: APIResponse<UserSettings> = try await fetch(url: url)
        return response.data
    }

    // MARK: - Private Helpers

    private func buildURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        var items = queryItems
        if let key = apiKey {
            items.append(URLQueryItem(name: "apikey", value: key))
        }
        guard var components = URLComponents(string: baseURL + path) else {
            throw FetchError.invalidURL
        }
        if !items.isEmpty {
            components.queryItems = items
        }
        guard let url = components.url else {
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
        } catch is CancellationError {
            throw FetchError.cancelled
        } catch {
            throw FetchError.networkError(error.localizedDescription)
        }
        try Task.checkCancellation()

        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200...299: break
            case 401: throw FetchError.unauthorized
            case 429:
                // Honor Retry-After header if present, otherwise back off 2s.
                let delay = http.value(forHTTPHeaderField: "Retry-After")
                    .flatMap(TimeInterval.init) ?? 2
                try? await Task.sleep(for: .seconds(min(delay, 10)))
                throw FetchError.rateLimited
            default:  throw FetchError.serverError(http.statusCode)
            }
        }

        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            throw FetchError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Configuration Helpers

    private static func resolveBaseURL() -> String {
        let stored = UserDefaults.standard.string(forKey: "wallhaven_api_base_url")
        return (stored?.isEmpty ?? true) ? defaultBaseURL : stored!
    }

    private static func resolveAPIKey() -> String? {
        let key = UserDefaults.standard.string(forKey: "wallhaven_api_key")
        return key?.isEmpty == false ? key : nil
    }
}

// MARK: - FetchError

enum FetchError: LocalizedError {
    case invalidURL
    case unauthorized
    case rateLimited
    case serverError(Int)
    case decodingError(String)
    case networkError(String)
    case cancelled

    var isRetryable: Bool {
        switch self {
        case .rateLimited, .serverError, .networkError: return true
        default: return false
        }
    }

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
        case .decodingError(let message):
            return String(
                format: NSLocalizedString("error.decoding", comment: ""),
                message
            )
        case .networkError(let message):
            return String(
                format: NSLocalizedString("error.network", comment: ""),
                message
            )
        case .cancelled:
            return NSLocalizedString("error.cancelled", comment: "")
        }
    }
}
