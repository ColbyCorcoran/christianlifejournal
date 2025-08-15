//
//  SermonNotesListView.swift
//  Christian Life Journal
//
//  Created by Claude on 8/15/25.
//

import SwiftUI
import SwiftData

struct SermonNotesListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var speakerStore: SpeakerStore
    
    // State for filtering
    @State private var searchText = ""
    @State private var selectedTagID: UUID? = nil
    @State private var selectedSpeaker: String? = nil
    @State private var hasScripture: Bool? = nil
    
    // State for sheets
    @State private var showAddSheet = false
    
    // SwiftData query for Sermon Notes entries
    @Query(
        filter: #Predicate<JournalEntry> { entry in
            entry.section == "Sermon Notes"
        },
        sort: \JournalEntry.date,
        order: .reverse
    ) var allSermonNotesEntries: [JournalEntry]
    
    // Filtered entries based on search and filters
    var filteredEntries: [JournalEntry] {
        var entries = allSermonNotesEntries
        
        // Apply tag filter
        if let tagID = selectedTagID {
            entries = entries.filter { $0.tagIDs.contains(tagID) }
        }
        
        // Apply speaker filter
        if let speaker = selectedSpeaker {
            entries = entries.filter { $0.speaker == speaker }
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
                entry.notes?.localizedCaseInsensitiveContains(searchText) == true ||
                entry.speaker?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return entries
    }
    
    // Build filter groups for the filter chip section
    var filterGroups: [FilterGroup] {
        var groups: [FilterGroup] = []
        
        // Add speaker filters if there are speakers
        if !speakerStore.speakers.isEmpty {
            let speakerGroup = SpeakerFilterBuilder.buildSpeakerFilters(
                speakers: speakerStore.speakers,
                selectedSpeaker: selectedSpeaker,
                onSpeakerSelected: { speaker in
                    selectedSpeaker = speaker
                }
            )
            groups.append(speakerGroup)
        }
        
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
            navigationTitle: "Sermon Notes",
            searchText: $searchText,
            searchPlaceholder: "Search sermon notes...",
            filterGroups: filterGroups,
            addButtonAction: { showAddSheet = true },
            addButtonLabel: "Add Sermon Notes"
        ) {
            // Content area
            if filteredEntries.isEmpty {
                SearchableEmptyState(
                    icon: "mic.fill",
                    title: "No Sermon Notes",
                    subtitle: "Take notes during sermons and teachings",
                    searchText: searchText,
                    addButtonAction: { showAddSheet = true },
                    addButtonTitle: "Add Sermon Notes"
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
            AddSermonNotesView(section: .sermonNotes)
                .environmentObject(tagStore)
                .environmentObject(speakerStore)
                .environment(\.modelContext, modelContext)
        }
        .onAppear {
            // Clear any stale filter state when view appears
            if !tagStore.userTags.contains(where: { $0.id == selectedTagID }) {
                selectedTagID = nil
            }
            if !speakerStore.speakers.contains(where: { $0.name == selectedSpeaker }) {
                selectedSpeaker = nil
            }
        }
    }
}

// MARK: - Preview

struct SermonNotesListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SermonNotesListView()
                .modelContainer(previewContainer)
                .environmentObject(previewTagStore)
                .environmentObject(previewSpeakerStore)
        }
    }
}
