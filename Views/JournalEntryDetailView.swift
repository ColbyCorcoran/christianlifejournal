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
    @EnvironmentObject var tagStore: TagStore

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

                // Tags section
                if !entry.tagIDs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.appGreenDark)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(entry.tagIDs, id: \.self) { tagID in
                                if let tag = tagStore.tag(for: tagID) {
                                    Text(tag.name)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.appGreenLight)
                                        )
                                        .foregroundColor(.appGreenDark)
                                }
                            }
                        }
                    }
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
            // FIXED: Remove tagStore and speakerStore parameters since they use @EnvironmentObject
            switch JournalSection(rawValue: entry.section) {
            case .personalTime:
                AddPersonalTimeView(entryToEdit: entry, section: .personalTime)
                    .environmentObject(tagStore)
            case .sermonNotes:
                AddSermonNotesView(entryToEdit: entry, section: .sermonNotes)
                    .environmentObject(tagStore)
                    .environmentObject(speakerStore)
            case .scriptureMemorization, .prayerJournal, .groupNotes, .other, .none:
                AddEntryView(entryToEdit: entry, section: JournalSection(rawValue: entry.section) ?? .other)
                    .environmentObject(tagStore)
            }
        }
    }
    
    // Helper function for date formatting
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
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
        // Add some sample tag IDs for preview
        entry.tagIDs = []
        
        return JournalEntryDetailView(entry: entry)
            .environmentObject(TagStore())
            .modelContainer(for: JournalEntry.self, inMemory: true)
    }
}
