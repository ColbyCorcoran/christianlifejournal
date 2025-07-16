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

    @State private var showEditSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(entry.title)
                    .font(.title)
                    .bold()
                Text(formattedDate(entry.date))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                // ...rest of your content...
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
                AddPersonalTimeView(entryToEdit: entry)
            case .sermonNotes:
                AddSermonNotesView(entryToEdit: entry)
            case .scriptureToMemorize, .prayerJournal, .groupNotes, .other, .none:
                AddEntryView(entryToEdit: entry)
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
            scripture: "",
            notes: ""
        )
        JournalEntryDetailView(entry: entry)
            .modelContainer(for: JournalEntry.self, inMemory: true)
    }
}
