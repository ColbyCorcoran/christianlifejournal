//
//  JournalModels.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import Foundation
import SwiftData

@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var section: String
    var title: String
    var date: Date

    // Optional fields for specialized sections
    var bodyText: String?
    var scripture: String?
    var notes: String?
    var speaker: String?
    var tagIDs: [UUID] = [] // Store the IDs of assigned tags

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

