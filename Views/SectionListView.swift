//
//  SectionListView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.

import SwiftUI
import SwiftData

struct SectionListView: View {
    @Environment(\.modelContext) private var modelContext
    let section: JournalSection
    @Query(sort: \JournalEntry.date, order: .reverse) private var allEntries: [JournalEntry]

    @State private var showAdd = false
    @State private var showEditSheet = false
    @State private var entryToEdit: JournalEntry?
    @State private var showDeleteAlert = false
    @State private var entryToDelete: JournalEntry?

    var entries: [JournalEntry] {
        allEntries.filter { $0.section == section.rawValue }
    }

    var body: some View {
        ZStack {
            Color.appWhite.ignoresSafeArea() // Custom background

            List {
                ForEach(entries) { entry in
                    SectionListRow(
                        entry: entry,
                        onEdit: {
                            entryToEdit = entry
                            showEditSheet = true
                        },
                        onDelete: {
                            entryToDelete = entry
                            showDeleteAlert = true
                        }
                    )
                }
            }
            .tint(Color.appGreenDark)
            .navigationTitle(section.rawValue)
            .alert("Delete Entry?", isPresented: $showDeleteAlert, presenting: entryToDelete) { entry in
                Button("Delete", role: .destructive) {
                    modelContext.delete(entry)
                }
                Button("Cancel", role: .cancel) {}
            } message: { entry in
                Text("Are you sure you want to delete \"\(entry.title)\"?")
            }
            .sheet(isPresented: $showAdd) {
                addEntrySheetView(for: section)
            }
            .sheet(isPresented: $showEditSheet) {
                editEntrySheetView(for: section, entry: entryToEdit)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Add/Edit Entry Sheet Helpers

    @ViewBuilder
    private func addEntrySheetView(for section: JournalSection) -> some View {
        switch section {
        case .prayerJournal, .groupNotes, .other:
            AddEntryView(section: section)
        case .personalTime:
            AddPersonalTimeView()
        case .sermonNotes:
            AddSermonNotesView()
        case .scriptureToMemorize:
            AddScriptureToMemorizeView()
        }
    }

    @ViewBuilder
    private func editEntrySheetView(for section: JournalSection, entry: JournalEntry?) -> some View {
        switch section {
        case .prayerJournal, .groupNotes, .other:
            AddEntryView(section: section, entryToEdit: entry)
        case .personalTime:
            AddPersonalTimeView(entryToEdit: entry)
        case .sermonNotes:
            AddSermonNotesView(entryToEdit: entry)
        case .scriptureToMemorize:
            AddScriptureToMemorizeView(entryToEdit: entry)
        }
    }
}

// MARK: - Helper Row View

struct SectionListRow: View {
    let entry: JournalEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        NavigationLink(destination: JournalEntryDetailView(entry: entry)) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.headline)
                Text(formattedDate(entry.date))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(Color.appGreenDark)
        }
    }
}

struct SectionListView_Previews: PreviewProvider {
    static var previews: some View {
        SectionListView(section: .sermonNotes)
            .modelContainer(for: JournalEntry.self, inMemory: true)
    }
}
