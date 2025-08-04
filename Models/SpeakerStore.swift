//
//  SpeakerStore.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/19/25.
//

import SwiftUI

// Speaker model with UUID for reliable identification
struct Speaker: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

class SpeakerStore: ObservableObject {
    @Published var speakers: [Speaker] = []

    func addSpeaker(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !speakers.contains(where: { $0.name == trimmed }) else { return }
        
        let newSpeaker = Speaker(name: trimmed)
        speakers.append(newSpeaker)
        
        // Force UI update
        objectWillChange.send()
    }

    // FIXED: Use UUID-based removal instead of index-based
    func removeSpeaker(withId id: UUID) {
        guard let index = speakers.firstIndex(where: { $0.id == id }) else { return }
        speakers.remove(at: index)
        objectWillChange.send()
    }
    
    // FIXED: Use UUID-based update instead of index-based
    func updateSpeaker(withId id: UUID, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let index = speakers.firstIndex(where: { $0.id == id }) else { return }
        
        // Check for duplicate names (excluding the current speaker)
        let isDuplicate = speakers.enumerated().contains { (idx, speaker) in
            idx != index && speaker.name == trimmed
        }
        
        guard !isDuplicate else { return }
        
        // Create new speaker with same ID but updated name
        speakers[index] = Speaker(name: trimmed)
        objectWillChange.send()
    }
    
    // Helper methods for backward compatibility
    var speakerNames: [String] {
        speakers.map { $0.name }
    }
    
    func speaker(for name: String) -> Speaker? {
        speakers.first { $0.name == name }
    }
    
    // MARK: - Preview Helper
    
    static var preview: SpeakerStore {
        let store = SpeakerStore()
        store.addSpeaker("Pastor John")
        store.addSpeaker("Dr. Smith")
        store.addSpeaker("Rev. Johnson")
        store.addSpeaker("Elder Brown")
        return store
    }
}

