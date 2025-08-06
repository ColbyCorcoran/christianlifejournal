//
//  JournalSection.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import Foundation

enum JournalSection: String, CaseIterable, Hashable {
    case personalTime = "Personal Time with God"
    case scriptureMemorization = "Scripture Memorization"
    case prayerJournal = "Prayer Journal"
    case sermonNotes = "Sermon Notes"
    case groupNotes = "Group Notes"
    case other = "Other"

    var displayName: String {
        switch self {
        case .personalTime: return "Personal Time"
        case .scriptureMemorization: return "Scripture Memorization"
        case .prayerJournal: return "Prayer Journal"
        case .sermonNotes: return "Sermon Notes"
        case .groupNotes: return "Group Notes"
        case .other: return "Other"
        }
    }
    
    // Indicates whether this section uses the new scripture memorization system
    var usesMemorizationSystem: Bool {
        return self == .scriptureMemorization
    }
    
    // Returns the icon for this section
    var systemImageName: String {
        switch self {
        case .personalTime: return "person.circle"
        case .scriptureMemorization: return "book.closed"
        case .prayerJournal: return "hands.sparkles"
        case .sermonNotes: return "mic"
        case .groupNotes: return "person.2"
        case .other: return "folder"
        }
    }
}
