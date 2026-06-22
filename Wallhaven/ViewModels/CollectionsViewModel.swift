import Foundation
import SwiftData

@Observable
@MainActor
final class CollectionsViewModel {

    func createCollection(named name: String, in context: ModelContext) {
        let collection = CollectionFolder(name: name)
        context.insert(collection)
        context.saveWithLog()
    }

    func deleteCollection(_ collection: CollectionFolder, in context: ModelContext) {
        let collectionID = collection.id
        let itemsDescriptor = FetchDescriptor<StoredWallpaper>(
            predicate: #Predicate { $0.collectionID == collectionID }
        )
        if let items = try? context.fetch(itemsDescriptor) {
            for item in items {
                context.delete(item)
            }
        }
        context.delete(collection)
        context.saveWithLog()
    }

    func renameCollection(_ collection: CollectionFolder, to name: String, in context: ModelContext) {
        collection.name = name
        context.saveWithLog()
    }

    func ensureDefaultCollection(in context: ModelContext) {
        let descriptor = FetchDescriptor<CollectionFolder>()
        guard let existing = try? context.fetch(descriptor), existing.isEmpty else { return }
        let defaultCollection = CollectionFolder(name: "Default", sortOrder: 0)
        context.insert(defaultCollection)
        context.saveWithLog()
    }
}
