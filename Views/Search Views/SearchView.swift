//
//  SearchView.swift
//  Christian Life Journal
//
//  Updated to include Scripture Memory Entries
//

import SwiftUI
import SwiftData

// Create a unified search result type
enum SearchResult: Identifiable, Hashable {
    case journalEntry(JournalEntry)
    case scriptureEntry(ScriptureMemoryEntry)
    
    var id: UUID {
        switch self {
        case .journalEntry(let entry): return entry.id
        case .scriptureEntry(let entry): return entry.id
        }
    }
    
    var title: String {
        switch self {
        case .journalEntry(let entry):
            return entry.title.isEmpty ? (entry.scripture ?? "Untitled") : entry.title
        case .scriptureEntry(let entry):
            return entry.bibleReference
        }
    }
    
    var date: Date {
        switch self {
        case .journalEntry(let entry): return entry.date
        case .scriptureEntry(let entry): return entry.dateAdded
        }
    }
    
    var sectionName: String {
        switch self {
        case .journalEntry(let entry): return entry.section
        case .scriptureEntry(_): return JournalSection.scriptureMemorization.rawValue
        }
    }
    
    var tagIDs: [UUID] {
        switch self {
        case .journalEntry(let entry): return entry.tagIDs
        case .scriptureEntry(let entry): return entry.tagIDs
        }
    }
}

// Navigation type for SearchView
enum SearchNav: Hashable {
    case journalEntry(UUID)
    case scriptureEntry(UUID)
}

struct SearchView: View {
    @Binding var searchText: String
    let allEntries: [JournalEntry]
    @Binding var showSearch: Bool
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var speakerStore: SpeakerStore
    @EnvironmentObject var memorizationSettings: MemorizationSettings

    @Binding var selectedTagIDs: Set<UUID>
    @Binding var selectedBooks: Set<String>
    @Binding var selectedSections: Set<String>
    @Binding var selectedSpeakers: Set<String>
    
    // Navigation callback to open entries in their native sections
    let onOpenEntry: (DashboardNav) -> Void

    // Add scripture entries query
    @Query(sort: \ScriptureMemoryEntry.dateAdded, order: .reverse)
    private var allScriptureEntries: [ScriptureMemoryEntry]

    @FocusState private var isSearchFocused: Bool
    @State private var searchNavPath: [SearchNav] = []
    @State private var selectedResult: SearchResult?

    // Combined search results
    var searchResults: [SearchResult] {
        let journalResults = allEntries.map { SearchResult.journalEntry($0) }
        let scriptureResults = allScriptureEntries.map { SearchResult.scriptureEntry($0) }
        
        let combined = journalResults + scriptureResults
        
        return combined.sorted { $0.date > $1.date } // Sort by date, newest first
    }

    var filteredResults: [SearchResult] {
        searchResults.filter { result in
            // Text search
            let matchesText = searchText.isEmpty || textMatches(result: result, searchText: searchText)

            // Bible book filter
            let matchesBook = selectedBooks.isEmpty || bookMatches(result: result, selectedBooks: selectedBooks)

            // Section filter
            let matchesSection = selectedSections.isEmpty ||
                selectedSections.contains(JournalSection(rawValue: result.sectionName)?.displayName ?? "")

            // Speaker filter (only applies to journal entries)
            let matchesSpeaker = selectedSpeakers.isEmpty || speakerMatches(result: result, selectedSpeakers: selectedSpeakers)

            // Tag filter
            let matchesTag = selectedTagIDs.isEmpty ||
                !(Set(result.tagIDs).isDisjoint(with: selectedTagIDs))

            return matchesText && matchesBook && matchesSection && matchesSpeaker && matchesTag
        }
    }
    
    // Helper functions for filtering
    private func textMatches(result: SearchResult, searchText: String) -> Bool {
        let lowercasedSearch = searchText.lowercased()
        
        switch result {
        case .journalEntry(let entry):
            return entry.title.lowercased().contains(lowercasedSearch) ||
                   (entry.scripture?.lowercased().contains(lowercasedSearch) ?? false) ||
                   (entry.notes?.lowercased().contains(lowercasedSearch) ?? false) ||
                   (entry.bodyText?.lowercased().contains(lowercasedSearch) ?? false)
        case .scriptureEntry(let entry):
            return entry.bibleReference.lowercased().contains(lowercasedSearch) ||
                   entry.passageText.lowercased().contains(lowercasedSearch)
        }
    }
    
    private func bookMatches(result: SearchResult, selectedBooks: Set<String>) -> Bool {
        switch result {
        case .journalEntry(let entry):
            return entry.scripture?.split(separator: ";").contains(where: { passage in
                selectedBooks.contains(where: { book in
                    passage.trimmingCharacters(in: .whitespaces).hasPrefix(book)
                })
            }) ?? false
        case .scriptureEntry(let entry):
            return selectedBooks.contains(where: { book in
                entry.bibleReference.hasPrefix(book)
            })
        }
    }
    
    private func speakerMatches(result: SearchResult, selectedSpeakers: Set<String>) -> Bool {
        switch result {
        case .journalEntry(let entry):
            return selectedSpeakers.contains(entry.speaker ?? "")
        case .scriptureEntry(_):
            return true // Scripture entries don't have speakers, so they pass this filter
        }
    }
    
    private func resetSearchParameters() {
        searchText = ""
        selectedTagIDs = []
        selectedBooks = []
        selectedSections = []
        selectedSpeakers = []
    }
    
    // MARK: - Helper Properties
    
    private var hasActiveFilters: Bool {
        !selectedTagIDs.isEmpty || !selectedBooks.isEmpty || !selectedSections.isEmpty || !selectedSpeakers.isEmpty
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: - Filter Helpers
    
    private enum FilterType {
        case book, section, speaker, tag
        
        var color: Color {
            switch self {
            case .book: return .appGreenDark
            case .section: return .appGreenMedium
            case .speaker: return .appGreenLight
            case .tag: return .appGreen
            }
        }
    }
    
    @ViewBuilder
    private func activeFilterChip(text: String, type: FilterType, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(type.color)
        )
    }
    
    // MARK: - Card Views
    
    @ViewBuilder
    private var searchBarCard: some View {
        HStack(spacing: 12) {
            // Search field container
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.appGreenDark)
                    .font(.system(size: 16, weight: .medium))
                
                TextField("Search entries and verses...", text: $searchText)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .font(.body)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.6))
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
            )
            
            // Cancel button
            Button(action: {
                resetSearchParameters()
                showSearch = false
            }) {
                Text("Cancel")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.appGreenDark)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.appWhite)
    }
    
    @ViewBuilder
    private var bottomFilterBar: some View {
        VStack(spacing: 0) {
            // Active filters display (only when there are active filters)
            if hasActiveFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Show active filter chips
                        ForEach(Array(selectedBooks), id: \.self) { book in
                            activeFilterChip(text: book, type: .book) {
                                selectedBooks.remove(book)
                            }
                        }
                        
                        ForEach(Array(selectedSections), id: \.self) { section in
                            activeFilterChip(text: section, type: .section) {
                                selectedSections.remove(section)
                            }
                        }
                        
                        ForEach(Array(selectedSpeakers), id: \.self) { speaker in
                            activeFilterChip(text: speaker, type: .speaker) {
                                selectedSpeakers.remove(speaker)
                            }
                        }
                        
                        ForEach(Array(selectedTagIDs), id: \.self) { tagID in
                            if let tagName = tagStore.tag(for: tagID)?.name {
                                activeFilterChip(text: tagName, type: .tag) {
                                    selectedTagIDs.remove(tagID)
                                }
                            }
                        }
                        
                        // Clear all button
                        Button(action: resetSearchParameters) {
                            Text("Clear All")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.appGreenDark)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.appGreenDark.opacity(0.3), lineWidth: 1)
                                        .background(Color.white)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            
            // Filter buttons in 2x2 grid for better spacing and readability
            VStack(spacing: 8) {
                // First row: Bible and Type
                HStack(spacing: 8) {
                    FilterButton<String>(
                        label: "Bible",
                        selected: selectedBooks,
                        options: bibleBooks.map { $0.name },
                        displayName: { $0 },
                        onSelect: { book in
                            if selectedBooks.contains(book) {
                                selectedBooks.remove(book)
                            } else {
                                selectedBooks.insert(book)
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)

                    FilterButton<String>(
                        label: "Type",
                        selected: selectedSections,
                        options: JournalSection.allCases.map { $0.displayName },
                        displayName: { $0 },
                        onSelect: { section in
                            if selectedSections.contains(section) {
                                selectedSections.remove(section)
                            } else {
                                selectedSections.insert(section)
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
                
                // Second row: Speakers and Tags
                HStack(spacing: 8) {
                    FilterButton<String>(
                        label: "Speakers",
                        selected: selectedSpeakers,
                        options: speakerStore.speakerNames,
                        displayName: { $0 },
                        onSelect: { speaker in
                            if selectedSpeakers.contains(speaker) {
                                selectedSpeakers.remove(speaker)
                            } else {
                                selectedSpeakers.insert(speaker)
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)

                    FilterButton<UUID>(
                        label: "Tags",
                        selected: selectedTagIDs,
                        options: tagStore.userTags.map { $0.id },
                        displayName: { id in tagStore.tag(for: id)?.name ?? "" },
                        onSelect: { tagID in
                            if selectedTagIDs.contains(tagID) {
                                selectedTagIDs.remove(tagID)
                            } else {
                                selectedTagIDs.insert(tagID)
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, hasActiveFilters ? 0 : 12)
            .padding(.bottom, 12)
        }
//        .background(
//            RoundedRectangle(cornerRadius: 20)
//                .fill(Color.white)
//                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
//        )
        .clipped()
    }
    
    @ViewBuilder
    private var resultsArea: some View {
        if searchText.isEmpty && !hasActiveFilters {
            emptyStateView
        } else if filteredResults.isEmpty {
            noResultsView
        } else {
            resultsListView
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.appGreenMedium.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Search Your Journal")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.appGreenDark)
                
                Text("Type to search across all your entries and verses, or use filters to narrow your results")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .frame(maxHeight: .infinity)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.appGreenMedium.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Results Found")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.appGreenDark)
                
                Text("Try adjusting your search terms or filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: resetSearchParameters) {
                Text("Clear All Filters")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appGreenDark)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appGreenDark.opacity(0.3), lineWidth: 1)
                            .background(Color.appGreenPale.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxHeight: .infinity)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var resultsListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(filteredResults.count) \(filteredResults.count == 1 ? "result" : "results")")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.appGreenDark)
                .padding(.horizontal, 4)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredResults) { result in
                        searchResultCard(result: result)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func searchResultCard(result: SearchResult) -> some View {
        Button(action: {
            selectedResult = result
        }) {
            HStack(alignment: .top, spacing: 12) {
                // Type icon
                switch result {
                case .journalEntry(_):
                    Image(systemName: "doc.text")
                        .font(.title3)
                        .foregroundColor(.appGreenDark)
                        .frame(width: 24)
                case .scriptureEntry(_):
                    Image(systemName: "book.closed")
                        .font(.title3)
                        .foregroundColor(.appGreenDark)
                        .frame(width: 24)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Title and metadata
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.title)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        HStack {
                            Text(formattedDate(result.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(JournalSection(rawValue: result.sectionName)?.displayName ?? result.sectionName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.appGreenLight.opacity(0.3))
                                )
                                .foregroundColor(.appGreenDark)
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        NavigationStack(path: $searchNavPath) {
            ZStack {
                Color.appWhite.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main content - just results
                    resultsArea
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16) // Reduced padding - just enough to separate from filter bar
                    
                    // Bottom UI stack
                    VStack(spacing: 0) {
                        // Filter bar
                        bottomFilterBar
                        
                        // Search bar card
                        searchBarCard
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(item: Binding<SearchResult?>(
            get: { selectedResult },
            set: { _ in selectedResult = nil }
        )) { result in
            NavigationStack {
                switch result {
                case .journalEntry(let entry):
                    VStack(spacing: 0) {
                        // Custom navigation bar
                        HStack {
                            Button(action: {
                                selectedResult = nil
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.appGreenDark)
                                    Text("Search")
                                        .foregroundColor(.appGreenDark)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // Navigate to journal entry in its section
                                if let section = JournalSection(rawValue: entry.section) {
                                    resetSearchParameters()
                                    showSearch = false
                                    onOpenEntry(.entryFromSection(section, entry.id))
                                }
                            }) {
                                Text("Open Entry")
                                    .foregroundColor(.appGreenDark)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.appWhite)
                        
                        // Journal entry detail view
                        JournalEntryDetailView(entry: entry)
                            .environmentObject(tagStore)
                            .environmentObject(speakerStore)
                            .environmentObject(memorizationSettings)
                    }
                    .navigationBarHidden(true)
                case .scriptureEntry(let entry):
                    VStack(spacing: 0) {
                        // Custom navigation bar
                        HStack {
                            Button(action: {
                                selectedResult = nil
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.appGreenDark)
                                    Text("Search")
                                        .foregroundColor(.appGreenDark)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // Navigate to scripture entry in its section
                                resetSearchParameters()
                                showSearch = false
                                onOpenEntry(.scriptureEntry(entry.id))
                            }) {
                                Text("Open Entry")
                                    .foregroundColor(.appGreenDark)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.appWhite)
                        
                        // Scripture flashcard without NavigationView
                        ScriptureFlashcardView(entry: entry, embedInNavigationView: false)
                            .environmentObject(tagStore)
                            .environmentObject(speakerStore)
                            .environmentObject(memorizationSettings)
                    }
                    .navigationBarHidden(true)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(
            searchText: .constant(""),
            allEntries: [],
            showSearch: .constant(true),
            selectedTagIDs: .constant([]),
            selectedBooks: .constant([]),
            selectedSections: .constant([]),
            selectedSpeakers: .constant([]),
            onOpenEntry: { _ in }
        )
        .environmentObject(previewTagStore)
        .environmentObject(previewSpeakerStore)
        .environmentObject(previewMemorizationSettings)
        .modelContainer(previewContainer)
    }
}
