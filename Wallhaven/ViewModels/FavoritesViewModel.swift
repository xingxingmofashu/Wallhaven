import Foundation
import SwiftData

@Observable
@MainActor
final class FavoritesViewModel {

    // MARK: - Favorite Operations

    func clearAll(context: ModelContext) {
        try? context.delete(model: FavoriteWallpaper.self)
        try? context.save()
    }
}
