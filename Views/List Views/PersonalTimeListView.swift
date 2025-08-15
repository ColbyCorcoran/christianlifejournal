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
    @EnvironmentObject var tagStore: TagStore
    
    // State for filtering
    @State private var searchText = ""
    @State private var selectedTagID: UUID? = nil
    @State private var hasScripture: Bool? = nil
    
    // State for sheets
    @State private var showAddSheet = false
    
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
            navigationTitle: "Personal Time with God",
            searchText: $searchText,
            searchPlaceholder: "Search personal time entries...",
            filterGroups: filterGroups,
            addButtonAction: { showAddSheet = true },
            addButtonLabel: "Add Personal Time Entry"
        ) {
            // Content area
            if filteredEntries.isEmpty {
                SearchableEmptyState(
                    icon: "person.circle",
                    title: "No Personal Time Entries",
                    subtitle: "Record personal devotions and reflections",
                    searchText: searchText,
                    addButtonAction: { showAddSheet = true },
                    addButtonTitle: "Add Personal Time Entry"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredEntries) { entry in
                            NavigationLink(value: DashboardNav.entry(entry.id)) {
                                JournalEntryRow(entry: entry)
                                    .environmentObject(tagStore)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .padding(.bottom, 120) // Space for search bar
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddPersonalTimeView()
                .environmentObject(tagStore)
                .environment(\.modelContext, modelContext)
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

struct PersonalTimeListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PersonalTimeListView()
                .modelContainer(previewContainer)
                .environmentObject(previewTagStore)
        }
    }
}
