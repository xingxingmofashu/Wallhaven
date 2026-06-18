import SwiftUI

struct FavoritesTab: View {
    let wallpapers: [Wallpaper]
    let onSelect: (Wallpaper) -> Void
    let removeFavorite: (String) -> Void

    var body: some View {
        if wallpapers.isEmpty {
            ContentUnavailableView(
                "No Favorites Yet",
                systemImage: "heart",
                description: Text("Tap the heart icon on any wallpaper detail to save it here.")
            )
        } else {
            GridView(
                wallpapers: wallpapers,
                onSelect: onSelect,
                contextMenu: { wallpaper in
                    AnyView(
                        Button(role: .destructive) {
                            removeFavorite(wallpaper.id)
                        } label: {
                            Label("Remove from Favorites", systemImage: "heart.slash")
                        }
                    )
                }
            )
        }
    }
}
