import Foundation
import SwiftData

@Observable
@MainActor
final class CollectionsViewModel {

    func createCollection(named name: String, in context: ModelContext) {
        let collection = WallhavenCollection(name: name)
        context.insert(collection)
        try? context.save()
    }

    func deleteCollection(_ collection: WallhavenCollection, in context: ModelContext) {
        let collectionID = collection.id
        let itemsDescriptor = FetchDescriptor<CollectionItem>(
            predicate: #Predicate { $0.collectionID == collectionID }
        )
        if let items = try? context.fetch(itemsDescriptor) {
            for item in items {
                context.delete(item)
            }
        }
        context.delete(collection)
        try? context.save()
    }

    func ensureDefaultCollection(in context: ModelContext) {
        let descriptor = FetchDescriptor<WallhavenCollection>()
        guard let existing = try? context.fetch(descriptor), existing.isEmpty else { return }
        let defaultCollection = WallhavenCollection(name: "Default", sortOrder: 0)
        context.insert(defaultCollection)
        try? context.save()
    }
}
