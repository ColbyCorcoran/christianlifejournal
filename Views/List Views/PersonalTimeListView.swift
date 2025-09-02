//
//  PersonalTimeListView.swift
//  Christian Life Journal
//
//  Created by Claude on 8/15/25.
//

import SwiftUI
import SwiftData

struct PersonalTimeListView: View {
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
    @State private var showSuccessAlert = false
    @State private var successMessage = ""
    
    // SwiftData query for Personal Time entries
    @Query(
        filter: #Predicate<JournalEntry> { entry in
            entry.section == "Personal Time with God"
        },
        sort: \JournalEntry.date,
        order: .reverse
    ) var allPersonalTimeEntries: [JournalEntry]
    
    // Filtered entries based on search and filters
    var filteredEntries: [JournalEntry] {
        var entries = allPersonalTimeEntries
        
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
            searchPlaceholder: "Search personal time entries...",
            filterGroups: filterGroups,
            addButtonAction: { showAddSheet = true },
            addButtonLabel: "Add Personal Time Entry"
        ) {
            // Content area
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.circle")
                            .font(.title2)
                            .foregroundColor(.appGreenDark)
                        Text("Personal Time with God")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.appGreenDark)
                    }
                    
                    Text("Record personal devotions and reflections")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Content based on entries
                if filteredEntries.isEmpty {
                    HStack {
                        Spacer()
                        SearchableEmptyState(
                            icon: "person.circle",
                            title: "No Entries",
                            searchText: searchText,
                            addButtonAction: { showAddSheet = true },
                            addButtonTitle: "Add Personal Time Entry"
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
                                    // Haptic feedback for selection change
                                    HapticFeedbackService.shared.bulkSelectionChanged()
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
            AddPersonalTimeView()
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
                VStack {
                    // Custom navigation bar
                    HStack {
                        Button("Cancel") {
                            bulkSelectedTagIDs.removeAll()
                            showBulkTagPicker = false
                        }
                        .foregroundColor(.appGreenDark)
                        
                        Spacer()
                        
                        Text("Add Tags")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Apply") {
                            // Apply tags when Apply is pressed
                            if !bulkSelectedTagIDs.isEmpty {
                                for entry in selectedEntries {
                                    for tagID in bulkSelectedTagIDs {
                                        if !entry.tagIDs.contains(tagID) {
                                            entry.tagIDs.append(tagID)
                                        }
                                    }
                                }
                                
                                do {
                                    try modelContext.save()
                                    
                                    // Show success message
                                    let tagCount = bulkSelectedTagIDs.count
                                    let entryCount = selectedEntries.count
                                    let tagText = tagCount == 1 ? "tag" : "tags"
                                    let entryText = entryCount == 1 ? "entry" : "entries"
                                    
                                    successMessage = "Added \(tagCount) \(tagText) to \(entryCount) \(entryText)"
                                    showSuccessAlert = true
                                    
                                } catch {
                                    print("Error saving bulk tag changes: \(error)")
                                }
                                
                                bulkSelectedTagIDs.removeAll()
                                selectedEntries.removeAll()
                                isEditing = false
                            }
                            showBulkTagPicker = false
                        }
                        .disabled(bulkSelectedTagIDs.isEmpty)
                        .foregroundColor(bulkSelectedTagIDs.isEmpty ? .gray : .appGreenDark)
                    }
                    .padding()
                    
                    Divider()
                    
                    TagPickerSheet(selectedTagIDs: $bulkSelectedTagIDs)
                        .environmentObject(tagStore)
                }
                .background(Color.appWhite.ignoresSafeArea())
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") { }
        } message: {
            Text(successMessage)
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

// MARK: - Journal Bulk Actions Sheet

struct JournalBulkActionsSheet: View {
    let selectedCount: Int
    @Binding var isPresented: Bool
    
    let onAddTags: () -> Void
    let onAddToBinders: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.appGreenDark)
                            .font(.title3)
                        Text("Bulk Actions")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.appGreenDark)
                    }
                    
                    Text("\(selectedCount) journal \(selectedCount == 1 ? "entry" : "entries") selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 0)
            }
            .listRowBackground(Color.appGreenPale.opacity(0.1))
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            
            Section("Actions") {
                Button(action: {
                    onAddTags()
                    isPresented = false
                }) {
                    actionRowView(
                        icon: "tag.circle.fill",
                        title: "Add Tags",
                        subtitle: "Apply tags to all selected journal entries"
                    )
                }
                
                Button(action: {
                    onAddToBinders()
                    isPresented = false
                }) {
                    actionRowView(
                        icon: "books.vertical.circle.fill",
                        title: "Add to Binders",
                        subtitle: "Add all selected entries to binders"
                    )
                }
                
                Button(action: {
                    onDelete()
                    isPresented = false
                }) {
                    actionRowView(
                        icon: "trash",
                        title: "Delete",
                        subtitle: "Permanently remove all selected entries",
                        isDestructive: true
                    )
                }
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
        .listSectionSpacing(.compact)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder
    private func actionRowView(icon: String, title: String, subtitle: String, isDestructive: Bool = false) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isDestructive ? .red : .appGreenDark)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct PersonalTimeListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PersonalTimeListView()
                .modelContainer(previewContainer)
                .environmentObject(previewTagStore)
        }
    }
}
