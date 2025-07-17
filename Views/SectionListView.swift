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

    @State private var addEntry: JournalEntry?
    @State private var showEditSheet = false
    @State private var entryToEdit: JournalEntry?
    @State private var showDeleteAlert = false
    @State private var entryToDelete: JournalEntry?

    var entries: [JournalEntry] {
        allEntries.filter { $0.section == section.rawValue }
    }

    var body: some View {
        ZStack {
            Color.appWhite.ignoresSafeArea()

            List {
                ForEach(entries) { entry in
                    SectionListRow(
                        entry: entry,
                        section: section,
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
            .sheet(item: $addEntry) { entry in
                addEntrySheetView(for: entry)
            }
            .sheet(isPresented: $showEditSheet) {
                if let entry = entryToEdit {
                    addEntrySheetView(for: entry)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let newEntry = JournalEntry(
                            section: section.rawValue,
                            title: "",
                            date: Date(),
                            scripture: "",
                            notes: ""
                        )
                        modelContext.insert(newEntry)
                        addEntry = newEntry
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private func addEntrySheetView(for entry: JournalEntry) -> some View {
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

// MARK: - Helper Row View

struct SectionListRow: View {
    let entry: JournalEntry
    let section: JournalSection
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        NavigationLink(destination: JournalEntryDetailView(entry: entry)) {
            VStack(alignment: .leading, spacing: 4) {
                if section == .personalTime {
                    // Date as main line, scripture as secondary
                    Text(formattedDate(entry.date))
                        .font(.headline)
                    Text(entry.scripture?.components(separatedBy: ";").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    // Title as main line, date as secondary
                    Text(entry.title)
                        .font(.headline)
                    Text(formattedDate(entry.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
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
