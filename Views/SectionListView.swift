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
    
    @EnvironmentObject var speakerStore: SpeakerStore
    @EnvironmentObject var tagStore: TagStore
    
    @State private var showAddEntry = false
    @State private var showEditSheet = false
    @State private var entryToEdit: JournalEntry?
    @State private var showDeleteAlert = false
    @State private var entryToDelete: JournalEntry?
    
    // Multi-select state
    @State private var isEditing = false
    @State private var selectedEntries: Set<JournalEntry> = []
    @State private var showTagPicker = false
    @State private var selectedTagIDs: Set<UUID> = []
    
    var entries: [JournalEntry] {
        allEntries.filter { $0.section == section.rawValue }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.appWhite.ignoresSafeArea()
            
            List(selection: $selectedEntries) {
                ForEach(entries) { entry in
                    if isEditing {
                        HStack {
                            Image(systemName: selectedEntries.contains(entry) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedEntries.contains(entry) ? .appGreenDark : .gray)
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedEntries.contains(entry) {
                                selectedEntries.remove(entry)
                            } else {
                                selectedEntries.insert(entry)
                            }
                        }
                    } else {
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
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.appWhite)
            .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
            
            // Bulk action bar
            if isEditing && !selectedEntries.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Button(action: { showDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                        Spacer()
                        Button(action: { showTagPicker = true }) {
                            Label("Add Tags", systemImage: "tag.circle.fill")
                                .foregroundColor(.appGreenDark)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.appWhite).shadow(radius: 4))
                    .padding(.horizontal)
                    .padding(.bottom, 90)
                }
                .transition(.move(edge: .bottom))
            }
            
            // Tag picker overlay
            if showTagPicker {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture { showTagPicker = false }
                TagPickerOverlay(
                    isPresented: $showTagPicker,
                    selectedTagIDs: $selectedTagIDs
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(2)
            }
            
            // Floating Add Entry Button
            Button(action: {
                showAddEntry = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.appGreenDark))
                    .shadow(radius: 3)
            }
            .padding(.trailing, 24)
            .padding(.bottom, 32)
            .accessibilityLabel("Add Entry")
        }
        .navigationTitle(section.rawValue)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    Button("Done") { isEditing = false; selectedEntries.removeAll() }
                } else {
                    Button("Edit") { isEditing = true }
                }
            }
        }
        .alert("Delete Entries?", isPresented: $showDeleteAlert) {
            if isEditing && !selectedEntries.isEmpty {
                Button("Delete", role: .destructive) {
                    for entry in selectedEntries {
                        modelContext.delete(entry)
                    }
                    selectedEntries.removeAll()
                    isEditing = false
                }
            } else if let entry = entryToDelete {
                Button("Delete", role: .destructive) {
                    modelContext.delete(entry)
                }
            }
            Button("Cancel", role: .cancel) {
                 
            }
        } message: {
            if isEditing && !selectedEntries.isEmpty {
                Text("Are you sure you want to delete the selected entries?")
            } else if let entry = entryToDelete {
                Text("Are you sure you want to delete \"\(entry.title)\"?")
            } else {
                Text("")
            }
        }
        .sheet(isPresented: $showAddEntry) {
            addEntrySheetView()
        }
        .sheet(isPresented: $showEditSheet) {
            if let entry = entryToEdit {
                addEntrySheetView(entry: entry)
            }
        }
        .onChange(of: showTagPicker) {
            if !showTagPicker && !selectedTagIDs.isEmpty {
                // Add selected tags to all selected entries
                for entry in selectedEntries {
                    var tagIDs = entry.tagIDs
                    tagIDs.append(contentsOf: selectedTagIDs.filter { !tagIDs.contains($0) })
                    entry.tagIDs = tagIDs
                }
                selectedTagIDs.removeAll()
            }
        }
        .scrollContentBackground(.hidden)
        .onAppear {
            // Clear any stale navigation state
            selectedEntries.removeAll()
            isEditing = false
        }
    }

    @ViewBuilder
    private func addEntrySheetView(entry: JournalEntry? = nil) -> some View {
        switch JournalSection(rawValue: entry?.section ?? section.rawValue) {
        case .personalTime:
            AddPersonalTimeView(entryToEdit: entry, section: section)
        case .sermonNotes:
            AddSermonNotesView(entryToEdit: entry, section: section)
        case .scriptureMemorization, .prayerJournal, .groupNotes, .other, .none:
            AddEntryView(entryToEdit: entry, section: section)
        }
    }
}

// Updated SectionListRow
struct SectionListRow: View {
    let entry: JournalEntry
    let section: JournalSection
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        NavigationLink(value: DashboardNav.entry(entry.id)) {
            VStack(alignment: .leading, spacing: 4) {
                if section == .personalTime {
                    Text(formattedDate(entry.date))
                        .font(.headline)
                    Text(entry.scripture?.components(separatedBy: ";").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
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

