import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "photo.stack") {
                HomeView()
            }
            Tab("Search", systemImage: "magnifyingglass") {
                SearchView()
            }
            Tab("Favorites", systemImage: "heart") {
                FavoritesView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FavoriteWallpaper.self, inMemory: true)
}
