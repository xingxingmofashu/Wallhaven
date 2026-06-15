import Foundation

// MARK: - API Errors

enum WallhavenError: LocalizedError {
    case invalidURL
    case unauthorized
    case rateLimited
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid request URL"
        case .unauthorized:         return "Invalid API key or unauthorized access"
        case .rateLimited:          return "Too many requests, please try again later (45 req/min limit)"
        case .serverError(let c):   return "Server error: \(c)"
        case .decodingError(let e): return "Failed to parse data: \(e.localizedDescription)"
        case .networkError(let e):  return "Network error: \(e.localizedDescription)"
        }
    }
}
