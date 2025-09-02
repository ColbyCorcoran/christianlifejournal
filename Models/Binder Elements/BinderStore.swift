//
//  BinderStore.swift
//  Christian Life Journal
//
//  Store for managing Binder CRUD operations
//

import SwiftUI
import SwiftData

class BinderStore: ObservableObject {
    @Published var binders: [Binder] = []
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Only refresh if not in preview mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            refresh()
        }
    }
    
    // MARK: - Data Management
    
    func refresh() {
        // Skip refresh in preview mode or if context seems invalid
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }
        
        let descriptor = FetchDescriptor<Binder>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
        )
        
        // Wrap the entire operation in a try-catch to prevent crashes
        do {
            let fetchedBinders = try modelContext.fetch(descriptor)
            binders = fetchedBinders
        } catch {
            print("⚠️ BinderStore refresh error: \(error.localizedDescription)")
            // Keep existing binders rather than clearing them
        }
    }
    
    // MARK: - CRUD Operations
    
    func addBinder(_ binder: Binder) {
        modelContext.insert(binder)
        
        do {
            try modelContext.save()
            refresh()
        } catch {
            print("Error adding binder: \(error)")
        }
    }
    
    func updateBinder(_ binder: Binder) {
        do {
            try modelContext.save()
            refresh()
        } catch {
            print("Error updating binder: \(error)")
        }
    }
    
    func deleteBinder(withId id: UUID) {
        guard let binder = binders.first(where: { $0.id == id }) else { return }
        
        modelContext.delete(binder)
        
        do {
            try modelContext.save()
            refresh()
        } catch {
            print("Error deleting binder: \(error)")
        }
    }
    
    func archiveBinder(withId id: UUID) {
        guard let binder = binders.first(where: { $0.id == id }) else { return }
        
        binder.isArchived = true
        updateBinder(binder)
    }
    
    // MARK: - Entry Management
    
    func addJournalEntry(_ entryID: UUID, toBinder binderID: UUID) {
        guard let binder = binders.first(where: { $0.id == binderID }) else { return }
        
        binder.addJournalEntry(entryID)
        updateBinder(binder)
    }
    
    func addScriptureEntry(_ entryID: UUID, toBinder binderID: UUID) {
        guard let binder = binders.first(where: { $0.id == binderID }) else { return }
        
        binder.addScriptureEntry(entryID)
        updateBinder(binder)
    }
    
    func addPrayerRequest(_ requestID: UUID, toBinder binderID: UUID) {
        guard let binder = binders.first(where: { $0.id == binderID }) else { return }
        
        binder.addPrayerRequest(requestID)
        updateBinder(binder)
    }
    
    func removeJournalEntry(_ entryID: UUID, fromBinder binderID: UUID) {
        guard let binder = binders.first(where: { $0.id == binderID }) else { return }
        
        binder.removeJournalEntry(entryID)
        updateBinder(binder)
    }
    
    func removeScriptureEntry(_ entryID: UUID, fromBinder binderID: UUID) {
        guard let binder = binders.first(where: { $0.id == binderID }) else { return }
        
        binder.removeScriptureEntry(entryID)
        updateBinder(binder)
    }
    
    func removePrayerRequest(_ requestID: UUID, fromBinder binderID: UUID) {
        guard let binder = binders.first(where: { $0.id == binderID }) else { return }
        
        binder.removePrayerRequest(requestID)
        updateBinder(binder)
    }
    
    // MARK: - Convenience Methods for Entry Objects
    
    func addEntry(_ entry: JournalEntry, to binderID: UUID) {
        addJournalEntry(entry.id, toBinder: binderID)
    }
    
    func addEntry(_ entry: ScriptureMemoryEntry, to binderID: UUID) {
        addScriptureEntry(entry.id, toBinder: binderID)
    }
    
    func addPrayerRequest(_ request: PrayerRequest, toBinder binderID: UUID) {
        addPrayerRequest(request.id, toBinder: binderID)
    }
    
    func addScriptureMemoryEntry(_ entry: ScriptureMemoryEntry, to binderID: UUID) {
        addScriptureEntry(entry.id, toBinder: binderID)
    }
    
    // Update binder associations - manages adding/removing based on current state
    func updateBinderAssociations(for entry: JournalEntry, selectedBinderIDs: Set<UUID>) {
        let currentBinders = bindersContaining(journalEntryID: entry.id)
        let currentBinderIDs = Set(currentBinders.map { $0.id })
        
        // Add to new binders
        let bindersToAdd = selectedBinderIDs.subtracting(currentBinderIDs)
        for binderID in bindersToAdd {
            addJournalEntry(entry.id, toBinder: binderID)
        }
        
        // Remove from binders no longer selected
        let bindersToRemove = currentBinderIDs.subtracting(selectedBinderIDs)
        for binderID in bindersToRemove {
            removeJournalEntry(entry.id, fromBinder: binderID)
        }
    }
    
    func updateBinderAssociations(for entry: ScriptureMemoryEntry, selectedBinderIDs: Set<UUID>) {
        let currentBinders = bindersContaining(scriptureEntryID: entry.id)
        let currentBinderIDs = Set(currentBinders.map { $0.id })
        
        // Add to new binders
        let bindersToAdd = selectedBinderIDs.subtracting(currentBinderIDs)
        for binderID in bindersToAdd {
            addScriptureEntry(entry.id, toBinder: binderID)
        }
        
        // Remove from binders no longer selected
        let bindersToRemove = currentBinderIDs.subtracting(selectedBinderIDs)
        for binderID in bindersToRemove {
            removeScriptureEntry(entry.id, fromBinder: binderID)
        }
    }
    
    func updateBinderAssociations(for request: PrayerRequest, selectedBinderIDs: Set<UUID>) {
        let currentBinders = bindersContaining(prayerRequestID: request.id)
        let currentBinderIDs = Set(currentBinders.map { $0.id })
        
        // Add to new binders
        let bindersToAdd = selectedBinderIDs.subtracting(currentBinderIDs)
        for binderID in bindersToAdd {
            addPrayerRequest(request.id, toBinder: binderID)
        }
        
        // Remove from binders no longer selected
        let bindersToRemove = currentBinderIDs.subtracting(selectedBinderIDs)
        for binderID in bindersToRemove {
            removePrayerRequest(request.id, fromBinder: binderID)
        }
    }

    // MARK: - Helper Methods
    
    func binder(for id: UUID?) -> Binder? {
        guard let id = id else { return nil }
        return binders.first(where: { $0.id == id })
    }
    
    func bindersContaining(journalEntryID: UUID) -> [Binder] {
        // Don't refresh automatically to avoid potential context issues
        // refresh()
        
        // Filter binders that contain the journal entry
        return binders.filter { binder in
            binder.contains(journalEntryID: journalEntryID)
        }
    }
    
    func bindersContaining(scriptureEntryID: UUID) -> [Binder] {
        return binders.filter { $0.contains(scriptureEntryID: scriptureEntryID) }
    }
    
    func bindersContaining(prayerRequestID: UUID) -> [Binder] {
        return binders.filter { $0.contains(prayerRequestID: prayerRequestID) }
    }
    
    // MARK: - Statistics
    
    var activeBinders: [Binder] {
        return binders.filter { !$0.isArchived }
    }
    
    var recentBinders: [Binder] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return binders.filter { $0.dateCreated >= thirtyDaysAgo }
    }
    
    var totalBinderCount: Int {
        return binders.count
    }
    
    // MARK: - Preview Store Creation
    static func previewStore(modelContext: ModelContext) -> BinderStore {
        let store = BinderStore.__createEmpty(modelContext: modelContext)
        
        // Create preview binders and insert them into the context
        let previewBinders = [
            Binder(name: "Romans Study", binderDescription: "13-week study through Romans", colorHex: "#4A7C59"),
            Binder(name: "Prayer Journal", binderDescription: "Personal prayer reflections", colorHex: "#7e997e"),
            Binder(name: "Sermon Notes", binderDescription: "Sunday morning messages", colorHex: "#9dbb9d")
        ]
        
        // Insert into model context
        for binder in previewBinders {
            modelContext.insert(binder)
        }
        
        // Save and refresh to get the data
        try? modelContext.save()
        store.binders = previewBinders
        
        return store
    }
    
    private static func __createEmpty(modelContext: ModelContext) -> BinderStore {
        let store = BinderStore(modelContext: modelContext)
        store.binders = [] // Start with empty binders for preview
        return store
    }
}