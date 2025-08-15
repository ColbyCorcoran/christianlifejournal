//
//  SpeakerStore.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/19/25.
//

import SwiftUI
import SwiftData

class SpeakerStore: ObservableObject {
    private var modelContext: ModelContext
    @Published var speakers: [Speaker] = []

    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Safe initialization for previews
        do {
            try loadSpeakers()
        } catch {
            print("SpeakerStore preview-safe init - database operations failed: \(error)")
            // Set empty speakers for previews if database fails
            speakers = []
        }
    }
    
    private func loadSpeakers() throws {
        let descriptor = FetchDescriptor<Speaker>(sortBy: [SortDescriptor(\.name)])
        speakers = try modelContext.fetch(descriptor)
    }

    // MARK: - Speaker Management

    func addSpeaker(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !speakers.contains(where: { $0.name == trimmed }) else { return }
        
        let newSpeaker = Speaker(name: trimmed)
        modelContext.insert(newSpeaker)
        
        do {
            try modelContext.save()
            try loadSpeakers() // Refresh from database
            objectWillChange.send()
        } catch {
            print("Error saving speaker: \(error)")
        }
    }

    func removeSpeaker(withId id: UUID) {
        guard let speakerToDelete = speakers.first(where: { $0.id == id }) else { return }
        
        modelContext.delete(speakerToDelete)
        
        do {
            try modelContext.save()
            try loadSpeakers() // Refresh from database
            objectWillChange.send()
        } catch {
            print("Error deleting speaker: \(error)")
        }
    }
    
    func updateSpeaker(withId id: UUID, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let speakerToUpdate = speakers.first(where: { $0.id == id }) else { return }
        
        // Check for duplicate names (excluding the current speaker)
        let isDuplicate = speakers.contains { speaker in
            speaker.id != id && speaker.name == trimmed
        }
        
        guard !isDuplicate else { return }
        
        speakerToUpdate.name = trimmed
        
        do {
            try modelContext.save()
            try loadSpeakers() // Refresh from database
            objectWillChange.send()
        } catch {
            print("Error updating speaker: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    var speakerNames: [String] {
        speakers.map { $0.name }
    }
    
    func speaker(for name: String) -> Speaker? {
        speakers.first { $0.name == name }
    }
    
    // MARK: - Refresh Method
    func refresh() {
        do {
            try loadSpeakers()
            objectWillChange.send()
        } catch {
            print("Error refreshing speakers: \(error)")
        }
    }
    
    // MARK: - Preview Store Creation
    static func previewStore(modelContext: ModelContext) -> SpeakerStore {
        let store = SpeakerStore.__createEmpty(modelContext: modelContext)
        // Add some hardcoded speakers for previews without database operations
        store.speakers = [
            Speaker.previewSpeaker(name: "Pastor John"),
            Speaker.previewSpeaker(name: "Dr. Smith"),
            Speaker.previewSpeaker(name: "Rev. Johnson"),
            Speaker.previewSpeaker(name: "Elder Brown")
        ]
        return store
    }
    
    private static func __createEmpty(modelContext: ModelContext) -> SpeakerStore {
        let store = SpeakerStore()
        store.modelContext = modelContext
        store.speakers = []
        return store
    }
    
    // Empty initializer for preview creation
    private init() {
        // Create a simple in-memory container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Speaker.self, configurations: config)
        self.modelContext = ModelContext(container)
        self.speakers = []
        // Skip all database operations for previews
    }
}
