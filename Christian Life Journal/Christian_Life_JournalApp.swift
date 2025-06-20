import SwiftUI
import SwiftData

@main
struct ChristianLifeJournalApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
        .modelContainer(for: JournalEntry.self)
    }
}
