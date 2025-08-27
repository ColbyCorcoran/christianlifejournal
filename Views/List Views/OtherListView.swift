//
//  OtherListView.swift
//  Christian Life Journal
//
//  Created by Claude on 8/15/25.
//

import SwiftUI
import SwiftData

struct OtherListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var binderStore: BinderStore
    
    // State for filtering
    @State private var searchText = ""
    @State private var selectedTagID: UUID? = nil
    @State private var hasScripture: Bool? = nil
    
    // State for sheets
    @State private var showAddSheet = false
    
    // Bulk selection state
    @State private var isEditing = false
    @State private var selectedEntries: Set<JournalEntry> = []
    @State private var showBulkActions = false
    @State private var showBulkBinderPicker = false
    @State private var showBulkTagPicker = false
    @State private var showDeleteConfirmation = false
    @State private var bulkSelectedTagIDs: Set<UUID> = []
    
    // SwiftData query for Other entries
    @Query(
        filter: #Predicate<JournalEntry> { entry in
            entry.section == "Other"
        },
        sort: \JournalEntry.date,
        order: .reverse
    ) var allOtherEntries: [JournalEntry]
    
    // Filtered entries based on search and filters
    var filteredEntries: [JournalEntry] {
        var entries = allOtherEntries
        
        // Apply tag filter
        if let tagID = selectedTagID {
            entries = entries.filter { $0.tagIDs.contains(tagID) }
        }
        
        // Apply scripture filter
        if let hasScriptureFilter = hasScripture {
            entries = entries.filter { entry in
                let entryHasScripture = entry.scripture?.isEmpty == false
                return entryHasScripture == hasScriptureFilter
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                entry.title.localizedCaseInsensitiveContains(searchText) ||
                entry.bodyText?.localizedCaseInsensitiveContains(searchText) == true ||
                entry.notes?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return entries
    }
    
    // Build filter groups for the filter chip section
    var filterGroups: [FilterGroup] {
        var groups: [FilterGroup] = []
        
        // Add tag filters if there are user tags
        if !tagStore.userTags.isEmpty {
            let tagGroup = TagFilterBuilder.buildTagFilters(
                tags: tagStore.userTags,
                selectedTagIDs: selectedTagID != nil ? Set([selectedTagID!]) : Set(),
                onTagSelected: { tagID in
                    selectedTagID = tagID
                }
            )
            groups.append(tagGroup)
        }
        
        // Add scripture filters
        let scriptureGroup = ScriptureFilterBuilder.buildScriptureFilters(
            hasScripture: hasScripture,
            onScriptureFilterSelected: { hasScriptureValue in
                hasScripture = hasScriptureValue
            }
        )
        groups.append(scriptureGroup)
        
        return groups
    }
    
    var body: some View {
        SearchableListLayout(
            navigationTitle: "",
            searchText: $searchText,
            searchPlaceholder: "Search other entries...",
            filterGroups: filterGroups,
            addButtonAction: { showAddSheet = true },
            addButtonLabel: "Add Other Entry"
        ) {
            // Content area
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.fill")
                            .font(.title2)
                            .foregroundColor(.appGreenDark)
                        Text("Other")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.appGreenDark)
                    }
                    
                    Text("Document miscellaneous thoughts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Content based on entries
                if filteredEntries.isEmpty {
                    HStack {
                        Spacer()
                        SearchableEmptyState(
                            icon: "doc",
                            title: "No Entries",
                            searchText: searchText,
                            addButtonAction: { showAddSheet = true },
                            addButtonTitle: "Add Other Entry"
                        )
                        Spacer()
                    }
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredEntries) { entry in
                            if isEditing {
                                HStack {
                                    Image(systemName: selectedEntries.contains(entry) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedEntries.contains(entry) ? .appGreenDark : .gray)
                                        .font(.title3)
                                    
                                    JournalEntryRow(entry: entry)
                                        .environmentObject(tagStore)
                                        .environmentObject(binderStore)
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
                                NavigationLink(value: DashboardNav.entry(entry.id)) {
                                    JournalEntryRow(entry: entry)
                                        .environmentObject(tagStore)
                                        .environmentObject(binderStore)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 120) // Space for search bar
                }
                
                Spacer(minLength: 120) // Space for search bar
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .medium))
                            Text("Back")
                        }
                    }
                    .foregroundColor(.appGreenDark)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    HStack {
                        let selectedCount = selectedEntries.count
                        if selectedCount > 0 {
                            Button("Actions (\(selectedCount))") {
                                showBulkActions = true
                            }
                            .foregroundColor(.appGreenDark)
                        }
                        
                        Button("Done") {
                            isEditing = false
                            selectedEntries.removeAll()
                        }
                    }
                } else {
                    Button("Select") { isEditing = true }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddEntryView(section: .other)
                .environmentObject(tagStore)
                .environment(\.modelContext, modelContext)
        }
        .sheet(isPresented: $showBulkActions) {
            JournalBulkActionsSheet(
                selectedCount: selectedEntries.count,
                isPresented: $showBulkActions,
                onAddTags: { showBulkTagPicker = true },
                onAddToBinders: { showBulkBinderPicker = true },
                onDelete: { showDeleteConfirmation = true }
            )
        }
        .sheet(isPresented: $showBulkBinderPicker) {
            BulkBinderPickerSheet(
                selectedItems: .journalEntries(Array(selectedEntries)),
                isPresented: $showBulkBinderPicker,
                onComplete: {
                    selectedEntries.removeAll()
                    isEditing = false
                }
            )
            .environmentObject(binderStore)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBulkTagPicker) {
            NavigationStack {
                TagPickerSheet(selectedTagIDs: $bulkSelectedTagIDs)
                    .environmentObject(tagStore)
                    .navigationTitle("Add Tags")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar(content: {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                bulkSelectedTagIDs.removeAll()
                                showBulkTagPicker = false
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Apply") {
                                // Add selected tags to all selected entries
                                for entry in selectedEntries {
                                    for tagID in bulkSelectedTagIDs {
                                        if !entry.tagIDs.contains(tagID) {
                                            entry.tagIDs.append(tagID)
                                        }
                                    }
                                }
                                
                                do {
                                    try modelContext.save()
                                } catch {
                                    print("Error saving bulk tag changes: \(error)")
                                }
                                
                                bulkSelectedTagIDs.removeAll()
                                selectedEntries.removeAll()
                                isEditing = false
                                showBulkTagPicker = false
                            }
                            .disabled(bulkSelectedTagIDs.isEmpty)
                        }
                    })
            }
        }
        .confirmationDialog(
            "Delete \(selectedEntries.count) entries?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                // Delete selected entries
                for entry in selectedEntries {
                    modelContext.delete(entry)
                }
                
                do {
                    try modelContext.save()
                } catch {
                    print("Error deleting entries: \(error)")
                }
                
                selectedEntries.removeAll()
                isEditing = false
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .onAppear {
            // Clear any stale filter state when view appears
            if !tagStore.userTags.contains(where: { $0.id == selectedTagID }) {
                selectedTagID = nil
            }
        }
    }
}

// MARK: - Preview

struct OtherListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OtherListView()
                .modelContainer(previewContainer)
                .environmentObject(previewTagStore)
        }
    }
}
