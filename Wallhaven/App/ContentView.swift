import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var navigationState = NavigationState()

    var body: some View {
        TabView(selection: $navigationState.selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "photo.stack") }
                .tag(NavigationState.Tab.home)

            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(NavigationState.Tab.search)

            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "heart") }
                .tag(NavigationState.Tab.favorites)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(NavigationState.Tab.settings)
        }
        .environment(navigationState)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FavoriteWallpaper.self, inMemory: true)
}
