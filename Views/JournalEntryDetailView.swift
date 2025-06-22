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
    @Environment(\.presentationMode) var presentationMode
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    let entry: JournalEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(entry.title)
                    .font(.title)
                    .bold()
                Text(formattedDate(entry.date))
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // Show fields based on section
                switch entry.section {
                case JournalSection.personalTime.rawValue:
                    if let scripture = entry.scripture, !scripture.isEmpty {
                        Text("Scripture: \(scripture)")
                            .font(.headline)
                    }
                    if let notes = entry.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.body)
                    }
                case JournalSection.sermonNotes.rawValue:
                    if let speaker = entry.speaker, !speaker.isEmpty {
                        Text("Speaker: \(speaker)")
                            .font(.headline)
                    }
                    if let notes = entry.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.body)
                    }
                case JournalSection.scriptureToMemorize.rawValue:
                    if let scripture = entry.scripture, !scripture.isEmpty {
                        Text("Scripture: \(scripture)")
                            .font(.headline)
                    }
                    if let notes = entry.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.body)
                    }
                default:
                    if let bodyText = entry.bodyText, !bodyText.isEmpty {
                        Text(bodyText)
                            .font(.body)
                    }
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.appWhite.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("") // Hide nav bar title
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            editEntrySheetView(for: entry.section, entry: entry)
        }
        .alert("Delete Entry?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(entry)
                presentationMode.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(entry.title)\"?")
        }
    }

    // Helper to choose the correct edit view
    @ViewBuilder
    private func editEntrySheetView(for sectionRaw: String, entry: JournalEntry) -> some View {
        switch sectionRaw {
        case JournalSection.personalTime.rawValue:
            AddPersonalTimeView(entryToEdit: entry)
        case JournalSection.sermonNotes.rawValue:
            AddSermonNotesView(entryToEdit: entry)
        case JournalSection.scriptureToMemorize.rawValue:
            AddScriptureToMemorizeView(entryToEdit: entry)
        case JournalSection.prayerJournal.rawValue, JournalSection.groupNotes.rawValue, JournalSection.other.rawValue:
            AddEntryView(section: JournalSection(rawValue: sectionRaw) ?? .other, entryToEdit: entry)
        default:
            AddEntryView(section: .other, entryToEdit: entry)
        }
    }
}

struct JournalEntryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let entry = JournalEntry(
            section: JournalSection.personalTime.rawValue,
            title: "Morning Devotion",
            date: Date(),
            bodyText: nil,
            scripture: "John 3:16",
            notes: "God so loved the world...",
            speaker: nil
        )
        JournalEntryDetailView(entry: entry)
            .modelContainer(for: JournalEntry.self, inMemory: true)
    }
}
