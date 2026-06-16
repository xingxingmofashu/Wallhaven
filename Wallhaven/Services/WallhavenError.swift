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
        case .invalidURL: return "Invalid request URL"
        case .unauthorized: return "Invalid API key or unauthorized access"
        case .rateLimited: return "Too many requests, please try again later (45 req/min limit)"
        case .serverError(let statusCode): return "Server error: \(statusCode)"
        case .decodingError(let underlyingError): return "Failed to parse data: \(underlyingError.localizedDescription)"
        case .networkError(let underlyingError): return "Network error: \(underlyingError.localizedDescription)"
        }
    }
}
