import SwiftUI
import SwiftData

@main
struct YourApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            JournalEntry.self,
            ScriptureMemoryEntry.self,
            Tag.self,
            Speaker.self,
            PrayerRequest.self,
            PrayerCategory.self
        ])
    }
}

// And create a ContentView that initializes the stores with modelContext
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        DashboardView()
            .environmentObject(TagStore(modelContext: modelContext))
            .environmentObject(SpeakerStore(modelContext: modelContext))
    }
}
