import SwiftUI
import SwiftData

@main
struct ChristianLifeJournalApp: App {
    @StateObject private var tagStore = TagStore() // Single instance
    @StateObject private var speakerStore = SpeakerStore()
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(tagStore) // Share with all child views
                .environmentObject(speakerStore)
        }
        .modelContainer(for: JournalEntry.self)
    }
}
