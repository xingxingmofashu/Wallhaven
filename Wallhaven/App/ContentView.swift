import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var navigationState = NavigationState()
    @AppStorage("app_appearance") private var appAppearance = 0

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
        .task {
            applyAppAppearance(appAppearance)
            await SettingsViewModel.shared.load()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FavoriteWallpaper.self, CollectionFolder.self], inMemory: true)
}
