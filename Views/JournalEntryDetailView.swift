//
//  JournalEntryDetailView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import SwiftUI
import SwiftData

struct JournalEntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let entry: JournalEntry
    
    @StateObject var speakerStore = SpeakerStore()
    @StateObject var tagStore = TagStore()

    @State private var showEditSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title (or date for Personal Time)
                if entry.section == JournalSection.personalTime.rawValue {
                    Text(formattedDate(entry.date))
                        .font(.title)
                        .bold()
                } else {
                    Text(entry.title)
                        .font(.title)
                        .bold()
                }

                // Date (if not Personal Time)
                if entry.section != JournalSection.personalTime.rawValue {
                    Text(formattedDate(entry.date))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                // Scripture passage(s)
                if let scripture = entry.scripture, !scripture.isEmpty {
                    Text(scripture)
                        .font(.headline)
                        .foregroundColor(.appGreenDark)
                }

                // Body/Notes
                if let notes = entry.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Divider()
                        .background(Color.appGreenDark)
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.appWhite.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            switch JournalSection(rawValue: entry.section) {
            case .personalTime:
                AddPersonalTimeView(entryToEdit: entry, tagStore: tagStore)
            case .sermonNotes:
                AddSermonNotesView(entryToEdit: entry, speakerStore: speakerStore, tagStore: tagStore)
            case .scriptureMemorization, .prayerJournal, .groupNotes, .other, .none:
                AddEntryView(entryToEdit: entry, tagStore: tagStore)
            }
        }
    }
}

struct JournalEntryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let entry = JournalEntry(
            section: JournalSection.sermonNotes.rawValue,
            title: "Sample",
            date: Date(),
            scripture: "John 3:16",
            notes: "This is the body text/notes for the entry."
        )
        JournalEntryDetailView(entry: entry)
            .modelContainer(for: JournalEntry.self, inMemory: true)
    }
}
