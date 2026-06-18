import Foundation

@Observable
@MainActor
final class NavigationState {
    var selectedTab: Tab = .home
    var searchQuery = ""
    var shouldSearch = false

    enum Tab: Hashable {
        case home, search, favorites, settings
    }

    func searchTag(_ tag: String) {
        searchQuery = tag
        shouldSearch = true
        selectedTab = .search
    }
}
