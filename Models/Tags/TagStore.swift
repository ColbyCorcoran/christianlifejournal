//
//  TagStore.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/30/25.
//

import SwiftUI
import SwiftData

class TagStore: ObservableObject {
    private var modelContext: ModelContext
    @Published var tags: [Tag] = []

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Safe initialization for previews
        do {
            try loadTags()
            try initializeDefaultTags()
        } catch {
            print("TagStore preview-safe init - database operations failed: \(error)")
            // Set empty tags for previews if database fails
            tags = []
        }
    }
    
    private func loadTags() throws {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        tags = try modelContext.fetch(descriptor)
    }
    
    private func initializeDefaultTags() throws {
        // Only add default tags if none exist
        let defaultTags = tags.filter { $0.type == .default }
        guard defaultTags.isEmpty else { return }
        
        // Add Bible book tags
        for book in bibleBooks {
            let tag = Tag(name: book.name, type: .default)
            modelContext.insert(tag)
        }
        
        // Add section tags
        for section in JournalSection.allCases {
            let tag = Tag(name: section.displayName, type: .default)
            modelContext.insert(tag)
        }
        
        // Save and reload
        try modelContext.save()
        try loadTags()
    }

    // MARK: - Tag Management

    func addUserTag(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              !tags.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        
        let newTag = Tag(name: trimmed, type: .user)
        modelContext.insert(newTag)
        
        do {
            try modelContext.save()
            try loadTags() // Refresh from database
            objectWillChange.send()
        } catch {
            print("Error saving tag: \(error)")
        }
    }

    func removeUserTag(withId id: UUID) {
        guard let tagToDelete = tags.first(where: { $0.id == id && $0.type == .user }) else { return }
        
        modelContext.delete(tagToDelete)
        
        do {
            try modelContext.save()
            try loadTags() // Refresh from database
            objectWillChange.send()
        } catch {
            print("Error deleting tag: \(error)")
        }
    }
    
    func updateUserTag(withId id: UUID, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let tagToUpdate = tags.first(where: { $0.id == id && $0.type == .user }) else { return }
        
        // Check for duplicate names (excluding the current tag)
        let isDuplicate = tags.contains { tag in
            tag.id != id && tag.name.caseInsensitiveCompare(trimmed) == .orderedSame
        }
        
        guard !isDuplicate else { return }
        
        tagToUpdate.name = trimmed
        
        do {
            try modelContext.save()
            try loadTags() // Refresh from database
            objectWillChange.send()
        } catch {
            print("Error updating tag: \(error)")
        }
    }

    // MARK: - Tag Queries

    var userTags: [Tag] {
        tags.filter { $0.type == .user }
    }

    var defaultTags: [Tag] {
        tags.filter { $0.type == .default }
    }
    
    func tag(for id: UUID) -> Tag? {
        tags.first { $0.id == id }
    }

    func tag(for name: String) -> Tag? {
        tags.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    func isDefaultTag(_ name: String) -> Bool {
        tag(for: name)?.type == .default
    }
    
    // MARK: - Refresh Method
    func refresh() {
        do {
            try loadTags()
            objectWillChange.send()
        } catch {
            print("Error refreshing tags: \(error)")
        }
    }
    
    // MARK: - Preview Store Creation
    static func previewStore(modelContext: ModelContext) -> TagStore {
        let store = TagStore.__createEmpty(modelContext: modelContext)
        // Add some hardcoded tags for previews without database operations
        store.tags = [
            Tag.previewTag(name: "Prayer", type: .default),
            Tag.previewTag(name: "Bible Study", type: .default),
            Tag.previewTag(name: "Personal", type: .user)
        ]
        return store
    }
    
    private static func __createEmpty(modelContext: ModelContext) -> TagStore {
        let store = TagStore()
        store.modelContext = modelContext
        store.tags = []
        return store
    }
    
    // Empty initializer for preview creation
    private init() {
        // Create a simple in-memory container
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Tag.self, configurations: config)
        self.modelContext = ModelContext(container)
        self.tags = []
        // Skip all database operations for previews
    }
}
