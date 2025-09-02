//
//  JournalModels.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import Foundation
import SwiftData
import CloudKit



@Model
class JournalEntry: Hashable {
    var id: UUID = UUID()
    var section: String = ""
    var title: String = ""
    var date: Date = Date()

    // Optional fields for specialized sections
    var bodyText: String?
    var scripture: String?
    var notes: String?
    var speaker: String?
    var tagIDs: [UUID] = [] // Store the IDs of assigned tags
    
    static func == (lhs: JournalEntry, rhs: JournalEntry) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

    init(
        id: UUID = UUID(),
        section: String,
        title: String,
        date: Date,
        bodyText: String? = nil,
        scripture: String? = nil,
        notes: String? = nil,
        speaker: String? = nil,
        tagIDs: [UUID] = []
    ) {
        self.id = id
        self.section = section
        self.title = title
        self.date = date
        self.bodyText = bodyText
        self.scripture = scripture
        self.notes = notes
        self.speaker = speaker
        self.tagIDs = tagIDs
    }
}

