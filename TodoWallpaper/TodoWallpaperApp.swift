import SwiftUI
import SwiftData

@main
struct TodoWallpaperApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: TodoItem.self)
    }
}
