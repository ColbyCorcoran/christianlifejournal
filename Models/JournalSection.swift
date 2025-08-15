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
    case prayerRequest = "Prayer Request"
    case sermonNotes = "Sermon Notes"
    case groupNotes = "Group Notes"
    case other = "Other"

    var displayName: String {
        switch self {
        case .personalTime: return "Personal Time with God"
        case .scriptureMemorization: return "Scripture Memorization"
        case .prayerJournal: return "Prayer Center"  // Dashboard display name
        case .prayerRequest: return "Prayer Request"
        case .sermonNotes: return "Sermon Notes"
        case .groupNotes: return "Group Notes"
        case .other: return "Other"
        }
    }
    
    // Name used for entry creation/selection (different from dashboard display)
    var entryTypeName: String {
        switch self {
        case .personalTime: return "Personal Time with God"
        case .scriptureMemorization: return "Scripture Memorization"
        case .prayerJournal: return "Prayer Journal"  // Entry creation uses "Prayer Journal"
        case .prayerRequest: return "Prayer Request"
        case .sermonNotes: return "Sermon Notes"
        case .groupNotes: return "Group Notes"
        case .other: return "Other"
        }
    }
    
    // Navigation title for individual entries (different from dashboard display name)
    var navigationTitle: String {
        switch self {
        case .personalTime: return "Personal Time"
        case .scriptureMemorization: return "Scripture Memorization"
        case .prayerJournal: return "Prayer Journal"  // Individual entries are still "Prayer Journal"
        case .prayerRequest: return "Prayer Request"
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
        case .prayerJournal: return "hands.sparkles"  // Dashboard icon (Prayer Center)
        case .prayerRequest: return "heart.fill"
        case .sermonNotes: return "mic"
        case .groupNotes: return "person.2"
        case .other: return "doc.fill"
        }
    }
    
    // Returns the icon for individual entries/lists of this section type
    var entryIconName: String {
        switch self {
        case .personalTime: return "person.circle"
        case .scriptureMemorization: return "book.closed"
        case .prayerJournal: return "book.pages.fill"  // Prayer Journal entries icon
        case .prayerRequest: return "heart.fill"
        case .sermonNotes: return "mic.fill"
        case .groupNotes: return "person.2"
        case .other: return "doc.fill"
        }
    }
}
