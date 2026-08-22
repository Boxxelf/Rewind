import SwiftData
import SwiftUI

@main
struct RewindApp: App {
    @State private var photos = PhotoLibraryService()

    var sharedModelContainer: ModelContainer = {
        let schema = RewindSchema.models
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            try? FileManager.default.removeItem(at: configuration.url)
            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(photos)
                .preferredColorScheme(nil)
        }
        .modelContainer(sharedModelContainer)
    }
}
