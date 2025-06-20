//
//  JournalViewModel.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import Foundation
import SwiftUI

class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    
    init() {
        loadDummyData()
    }
    
    func loadDummyData() {
        let today = Calendar.current.startOfDay(for: Date())
        if !entries.contains(where: { $0.section == .personalTime && Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            entries.append(JournalEntry(section: .personalTime, title: "Personal Time - \(formattedDate(today))", date: today, bodyText: "Today I reflected on..."))
        }
        entries.append(contentsOf: [
            JournalEntry(section: .scriptureToMemorize, title: "Romans 12:2", date: Date().addingTimeInterval(-86400 * 2), scripture: "Romans 12:2", notes: "Renew your mind."),
            JournalEntry(section: .groupNotes, title: "June 18 Small Group", date: Date().addingTimeInterval(-86400 * 2), bodyText: "Discussed faith and works."),
            JournalEntry(section: .sermonNotes, title: "Sunday Sermon: Faith", date: Date().addingTimeInterval(-86400 * 3), notes: "Faith is trusting God.", speaker: "Pastor Smith"),
            JournalEntry(section: .prayerJournal, title: "Answered Prayers", date: Date().addingTimeInterval(-86400 * 4), bodyText: "Thankful for..."),
            JournalEntry(section: .other, title: "Retreat Notes", date: Date().addingTimeInterval(-86400 * 5), bodyText: "Great retreat experience.")
        ])
    }
    
    func addEntry(section: JournalSection, title: String, date: Date, bodyText: String? = nil) {
        entries.append(JournalEntry(section: section, title: title, date: date, bodyText: bodyText))
    }
    
    func addPersonalTimeEntry(title: String, date: Date, scripture: String?, notes: String?) {
        entries.append(JournalEntry(section: .personalTime, title: title, date: date, scripture: scripture, notes: notes))
    }
    
    func addSermonNotesEntry(title: String, date: Date, speaker: String?, notes: String?) {
        entries.append(JournalEntry(section: .sermonNotes, title: title, date: date, notes: notes, speaker: speaker))
    }
    
    func addScriptureToMemorizeEntry(title: String, date: Date, scripture: String?, notes: String?) {
        entries.append(JournalEntry(section: .scriptureToMemorize, title: title, date: date, scripture: scripture, notes: notes))
    }
    
    func entries(for section: JournalSection) -> [JournalEntry] {
        entries.filter { $0.section == section }.sorted { $0.date > $1.date }
    }

    func updateEntry(_ entry: JournalEntry) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[idx] = entry
        }
    }

    func deleteEntry(_ entry: JournalEntry) {
        entries.removeAll { $0.id == entry.id }
    }

}
