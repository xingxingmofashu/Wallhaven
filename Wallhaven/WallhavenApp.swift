import SwiftUI
import SwiftData

@main
struct WallhavenApp: App {

    private let modelContainer: ModelContainer = {
        let schema = Schema([
            StoredWallpaper.self,
            CollectionFolder.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
