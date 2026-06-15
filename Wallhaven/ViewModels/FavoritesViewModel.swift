import Foundation
import SwiftData

@Observable
final class FavoritesViewModel {

    // MARK: - 收藏操作（通过 ModelContext 直接操作）

    /// 添加收藏
    func add(wallpaper: Wallpaper, context: ModelContext) {
        // 避免重复收藏
        guard !isFavorite(id: wallpaper.id, context: context) else { return }
        let fav = FavoriteWallpaper(from: wallpaper)
        context.insert(fav)
        try? context.save()
    }

    /// 移除收藏
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

    /// 切换收藏状态
    func toggle(wallpaper: Wallpaper, context: ModelContext) {
        if isFavorite(id: wallpaper.id, context: context) {
            remove(wallpaper: wallpaper, context: context)
        } else {
            add(wallpaper: wallpaper, context: context)
        }
    }

    /// 查询是否已收藏
    func isFavorite(id: String, context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<FavoriteWallpaper>(
            predicate: #Predicate { $0.wallpaperID == id }
        )
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }

    /// 清空所有收藏
    func clearAll(context: ModelContext) {
        try? context.delete(model: FavoriteWallpaper.self)
        try? context.save()
    }
}
