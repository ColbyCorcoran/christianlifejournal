//
//  Binder.swift
//  Christian Life Journal
//
//  Created for organizing entries into collections
//

import SwiftUI
import SwiftData

@Model
class Binder {
    var id: UUID
    var name: String
    var binderDescription: String?
    var dateCreated: Date
    var journalEntryIDs: [UUID]
    var scriptureEntryIDs: [UUID] 
    var prayerRequestIDs: [UUID]
    var colorHex: String
    var isArchived: Bool
    
    init(name: String, binderDescription: String? = nil, colorHex: String = "#4A7C59") {
        self.id = UUID()
        self.name = name
        self.binderDescription = binderDescription
        self.dateCreated = Date()
        self.journalEntryIDs = []
        self.scriptureEntryIDs = []
        self.prayerRequestIDs = []
        self.colorHex = colorHex
        self.isArchived = false
    }
}

// MARK: - Helper Extensions

extension Binder {
    var totalEntryCount: Int {
        return journalEntryIDs.count + scriptureEntryIDs.count + prayerRequestIDs.count
    }
    
    var formattedDateCreated: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dateCreated)
    }
    
    var color: Color {
        return Color(hex: colorHex)
    }
    
    // Check if this binder contains a specific entry
    func contains(journalEntryID: UUID) -> Bool {
        return journalEntryIDs.contains(journalEntryID)
    }
    
    func contains(scriptureEntryID: UUID) -> Bool {
        return scriptureEntryIDs.contains(scriptureEntryID)
    }
    
    func contains(prayerRequestID: UUID) -> Bool {
        return prayerRequestIDs.contains(prayerRequestID)
    }
    
    // Add entries to binder
    func addJournalEntry(_ entryID: UUID) {
        if !journalEntryIDs.contains(entryID) {
            journalEntryIDs.append(entryID)
        }
    }
    
    func addScriptureEntry(_ entryID: UUID) {
        if !scriptureEntryIDs.contains(entryID) {
            scriptureEntryIDs.append(entryID)
        }
    }
    
    func addPrayerRequest(_ requestID: UUID) {
        if !prayerRequestIDs.contains(requestID) {
            prayerRequestIDs.append(requestID)
        }
    }
    
    // Remove entries from binder
    func removeJournalEntry(_ entryID: UUID) {
        journalEntryIDs.removeAll { $0 == entryID }
    }
    
    func removeScriptureEntry(_ entryID: UUID) {
        scriptureEntryIDs.removeAll { $0 == entryID }
    }
    
    func removePrayerRequest(_ requestID: UUID) {
        prayerRequestIDs.removeAll { $0 == requestID }
    }
    
    // Default color options for binders
    static var defaultColors: [String] {
        return [
            "#4A7C59", // appGreenMedium
            "#8B6B4A", // Muted warm brown
            "#9AB6C7", // Light steel blue  
            "#5B7A9A", // Muted blue
            "#8B7A9A", // Muted purple
            "#B5A56B", // Light muted gold
            "#9A5B5B", // Muted red
            "#6B6B6B"  // Muted gray
        ]
    }
}