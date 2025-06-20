//
//  JournalSection.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import Foundation

enum JournalSection: String, CaseIterable, Identifiable, Hashable {
    case personalTime = "Personal Time with God"
    case scriptureToMemorize = "Scripture to Memorize"
    case groupNotes = "Group Notes"
    case sermonNotes = "Sermon Notes"
    case prayerJournal = "Prayer Journal"
    case other = "Other"
    
    var id: String { self.rawValue }
}

