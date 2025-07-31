//
//  JournalSection.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import Foundation

enum JournalSection: String, CaseIterable {
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
}
