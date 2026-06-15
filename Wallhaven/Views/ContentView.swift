import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("首页", systemImage: "photo.stack") {
                HomeView()
            }
            Tab("搜索", systemImage: "magnifyingglass") {
                SearchView()
            }
            Tab("收藏", systemImage: "heart") {
                FavoritesView()
            }
            Tab("设置", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FavoriteWallpaper.self, inMemory: true)
}
