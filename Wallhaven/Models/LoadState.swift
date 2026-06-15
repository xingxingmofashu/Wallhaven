import Foundation

/// Shared loading state for view models
enum LoadState {
    case idle
    case loading
    case loaded
    case failed(Error)
}
