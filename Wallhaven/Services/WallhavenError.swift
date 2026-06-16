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
