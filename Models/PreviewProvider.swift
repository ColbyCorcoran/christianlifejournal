//
//  PreviewProvider.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/7/25.
//

import SwiftUI
import SwiftData

extension PreviewProvider {
    static var previewContainer: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: Tag.self, Speaker.self, JournalEntry.self, ScriptureMemoryEntry.self, PrayerRequest.self, PrayerCategory.self, configurations: config)
    }
    
    static var previewContext: ModelContext {
        previewContainer.mainContext
    }
    
    static var previewTagStore: TagStore {
        // Create a simple TagStore with empty initialization
        return TagStore.previewStore(modelContext: previewContext)
    }
    
    static var previewSpeakerStore: SpeakerStore {
        // Create a simple SpeakerStore with empty initialization
        return SpeakerStore.previewStore(modelContext: previewContext)
    }
    
    static var previewMemorizationSettings: MemorizationSettings {
        MemorizationSettings()
    }
    
    // SwiftData-free preview stores - use actual stores with preview context
    static var previewPrayerCategoryStore: PrayerCategoryStore {
        PrayerCategoryStore(modelContext: previewContext)
    }
    
    static var previewPrayerRequestStore: PrayerRequestStore {
        PrayerRequestStore(modelContext: previewContext)
    }
    
    // Preview model instances
    static var previewJournalEntry: JournalEntry {
        JournalEntry(
            section: "Prayer Journal",
            title: "Sample Prayer Entry",
            date: Date(),
            notes: "This is a sample prayer journal entry for preview purposes."
        )
    }
    
    static var previewScriptureMemoryEntry: ScriptureMemoryEntry {
        ScriptureMemoryEntry(
            bibleReference: "John 3:16",
            passageText: "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.",
            dateAdded: Date(),
            currentPhase: .phase1,
            isSystemManaged: true
        )
    }
    
    static var previewPrayerRequest: PrayerRequest {
        PrayerRequest(
            title: "Healing for Mom",
            requestDescription: "Please pray for my mother's recovery from surgery. She's been struggling with complications and could use prayers for healing and peace.",
            dateAdded: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            isAnswered: false
        )
    }
    
    // Helper function for manual container creation
    static func createPreviewContainer() -> ModelContainer {
        return previewContainer
    }
}

// MARK: - NUCLEAR OPTION: Completely SwiftData-Free Mock Stores

class PreviewOnlyPrayerCategoryStore: ObservableObject {
    @Published var categories: [PrayerCategory] = []
    
    func categoryName(for id: UUID?) -> String? {
        guard let id = id else { return nil }
        return categories.first(where: { $0.id == id })?.name
    }
    
    func category(for id: UUID?) -> PrayerCategory? {
        guard let id = id else { return nil }
        return categories.first(where: { $0.id == id })
    }
    
    func addCategory(_ name: String) {}
    func removeCategory(withId id: UUID) {}  
    func updateCategory(withId id: UUID, newName: String) {}
    func refresh() {}
}

class PreviewOnlyPrayerRequestStore: ObservableObject {
    @Published var prayerRequests: [PrayerRequest] = []
    
    var totalActiveRequests: Int {
        prayerRequests.filter { !$0.isAnswered }.count
    }
    
    var recentlyAnsweredCount: Int {
        let currentDate = Date()
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: currentDate)?.start ?? currentDate
        return prayerRequests.filter { request in
            if let answerDate = request.dateAnswered {
                return answerDate >= startOfMonth && request.isAnswered
            }
            return false
        }.count
    }
    
    func addPrayerRequest(_ request: PrayerRequest) {}
    func updatePrayerRequest(_ request: PrayerRequest) {}
    func markAsAnswered(_ request: PrayerRequest, answerDate: Date = Date(), answerNotes: String? = nil) {}
    func markAsUnanswered(_ request: PrayerRequest) {}
    func refresh() {}
}
