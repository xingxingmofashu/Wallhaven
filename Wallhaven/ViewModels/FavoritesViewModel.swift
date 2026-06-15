import Foundation
import SwiftData

@Observable
@MainActor
final class FavoritesViewModel {

    // MARK: - Favorite Operations (via ModelContext)

    /// Add to favorites
    func add(wallpaper: Wallpaper, context: ModelContext) {
        // Prevent duplicate favorites
        guard !isFavorite(id: wallpaper.id, context: context) else { return }
        let fav = FavoriteWallpaper(from: wallpaper)
        context.insert(fav)
        try? context.save()
    }

    /// Remove from favorites
    func remove(wallpaper: Wallpaper, context: ModelContext) {
        let id = wallpaper.id
        let descriptor = FetchDescriptor<FavoriteWallpaper>(
            predicate: #Predicate { $0.wallpaperID == id }
        )
        if let fav = try? context.fetch(descriptor).first {
            context.delete(fav)
            try? context.save()
        }
    }

    /// Toggle favorite status
    func toggle(wallpaper: Wallpaper, context: ModelContext) {
        if isFavorite(id: wallpaper.id, context: context) {
            remove(wallpaper: wallpaper, context: context)
        } else {
            add(wallpaper: wallpaper, context: context)
        }
    }

    /// Check if already favorited
    func isFavorite(id: String, context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<FavoriteWallpaper>(
            predicate: #Predicate { $0.wallpaperID == id }
        )
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }

    /// Clear all favorites
    func clearAll(context: ModelContext) {
        try? context.delete(model: FavoriteWallpaper.self)
        try? context.save()
    }
}
