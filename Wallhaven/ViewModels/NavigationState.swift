import Foundation

@Observable
final class NavigationState {
    var selectedTab: Tab = .home
    var searchQuery = ""
    var shouldSearch = false

    enum Tab: Hashable {
        case home, search, favorites, collections, settings
    }

    func searchTag(_ tag: String) {
        searchQuery = tag
        shouldSearch = true
        selectedTab = .search
    }
}
