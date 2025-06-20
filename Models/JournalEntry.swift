//
//  JournalEntry.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import Foundation

struct JournalEntry: Identifiable, Hashable {
    let id: UUID
    let section: JournalSection
    let title: String
    let date: Date

    // Optional fields for specific sections
    var bodyText: String?                // For generic, Personal Time, etc.
    var scripture: String?               // For Personal Time, Scripture to Memorize
    var notes: String?                   // For Personal Time, Scripture to Memorize, Sermon Notes
    var speaker: String?                 // For Sermon Notes

    init(
        id: UUID = UUID(),
        section: JournalSection,
        title: String,
        date: Date,
        bodyText: String? = nil,
        scripture: String? = nil,
        notes: String? = nil,
        speaker: String? = nil
    ) {
        self.id = id
        self.section = section
        self.title = title
        self.date = date
        self.bodyText = bodyText
        self.scripture = scripture
        self.notes = notes
        self.speaker = speaker
    }
}
