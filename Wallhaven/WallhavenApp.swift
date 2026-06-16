import SwiftUI
import SwiftData

@main
struct WallhavenApp: App {

    private let modelContainer: ModelContainer = {
        let schema = Schema([FavoriteWallpaper.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }()

    init() {
        let raw = UserDefaults.standard.string(forKey: "AppLanguage") ?? ""
        if !raw.isEmpty {
            Bundle.setLanguage(raw)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
