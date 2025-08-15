//
//  DashboardView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.

import SwiftUI
import SwiftData


enum DashboardNav: Hashable {
    // Legacy generic section route (will be phased out)
    case section(JournalSection)
    case entryFromSection(JournalSection, UUID) // Entry with section context
    case scriptureEntry(UUID)
    
    // Specific list views with contextual search
    case personalTime
    case sermonNotes
    case scriptureMemorization
    case groupNotes
    case prayerJournal
    case prayerRequests
    case other
    
    // Entry details
    case entry(UUID) // Individual journal entry
    case prayerRequest(UUID) // Individual prayer request
    
}

// Identifiable wrapper for reliable sheet presentation
struct IdentifiableSection: Identifiable {
    let id = UUID()
    let section: JournalSection
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var allEntries: [JournalEntry]
    @Query(sort: \ScriptureMemoryEntry.dateAdded, order: .reverse)
    private var allScriptureEntries: [ScriptureMemoryEntry]
    @State private var path: [DashboardNav] = []
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var showSettings = false
    @State private var showQuickAdd = false
    @State private var showTagManagement = false
    @State private var showSpeakerManagement = false
    @State private var showPrayerCategoryManagement = false
    @State private var quickAddOption: QuickAddOption? = nil
    
    @State private var presentedSection: IdentifiableSection?

    @EnvironmentObject var speakerStore: SpeakerStore
    @EnvironmentObject var tagStore: TagStore
    @StateObject private var memorizationSettings = MemorizationSettings()
    
    // Prayer-related stores (initialized with modelContext)
    @State private var prayerRequestStore: PrayerRequestStore?
    @State private var prayerCategoryStore: PrayerCategoryStore?

    // Search filter state
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var selectedBooks: Set<String> = []
    @State private var selectedSections: Set<String> = []
    @State private var selectedSpeakers: Set<String> = []

    private let menuSections: [JournalSection] = [
        .personalTime,
        .scriptureMemorization,
        .prayerJournal,
        .sermonNotes,
        .groupNotes,
        .other
    ]
    
    
    @State private var navigationKey = UUID() // Add this to force NavigationStack recreation
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                VStack(spacing: 0) {
                    sectionCards
                        .padding(.top, 32)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 0)

                    Spacer(minLength: 0)

                    // Search bar and quick add button
                    HStack(spacing: 12) {
                        Button(action: {
                            showSearch = true
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.appGreenDark)
                                Text("Search entries and verses...")
                                    .foregroundColor(.appGreenDark.opacity(0.7))
                                    .font(.body)
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            showQuickAdd = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.appGreenDark))
                                .shadow(radius: 3)
                        }
                        .accessibilityLabel("Quick Add")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color.appWhite.ignoresSafeArea())

            }
            .sheet(item: $presentedSection) { identifiableSection in
                addEntrySheetView(for: identifiableSection.section)
            }
            .sheet(isPresented: $showSearch) {
                SearchView(
                    searchText: $searchText,
                    allEntries: allEntries,
                    showSearch: $showSearch,
                    selectedTagIDs: $selectedTagIDs,
                    selectedBooks: $selectedBooks,
                    selectedSections: $selectedSections,
                    selectedSpeakers: $selectedSpeakers,
                    onOpenEntry: { navigation in
                        // Navigate to the entry via its section list for proper back button behavior
                        DispatchQueue.main.async {
                            switch navigation {
                            case .entryFromSection(let section, let entryID):
                                // First navigate to section, then to entry
                                path.append(.section(section))
                                path.append(.entryFromSection(section, entryID))
                            case .scriptureEntry(let entryID):
                                // First navigate to scripture section, then to entry
                                path.append(.section(.scriptureMemorization))
                                path.append(.scriptureEntry(entryID))
                            case .section(_):
                                // Direct section navigation
                                path.append(navigation)
                            case .prayerRequests:
                                // Navigate directly to prayer requests
                                path.append(.prayerRequests)
                            case .prayerRequest(let requestID):
                                // Navigate to individual prayer request
                                path.append(.prayerRequests)
                                path.append(.prayerRequest(requestID))
                            case .personalTime:
                                path.append(.personalTime)
                            case .sermonNotes:
                                path.append(.sermonNotes)
                            case .scriptureMemorization:
                                path.append(.scriptureMemorization)
                            case .groupNotes:
                                path.append(.groupNotes)
                            case .prayerJournal:
                                path.append(.prayerJournal)
                            case .other:
                                path.append(.other)
                            case .entry(let entryID):
                                path.append(.entry(entryID))
                            }
                        }
                    }
                )
                .environmentObject(tagStore)
                .environmentObject(speakerStore)
                .environmentObject(memorizationSettings) // Add this line
                .interactiveDismissDisabled() // Prevent accidental dismissal
            }
            .sheet(isPresented: $showSettings) {
                NewSettingsView(isPresented: $showSettings)
                    .environmentObject(tagStore)
                    .environmentObject(speakerStore)
                    .environmentObject(getPrayerCategoryStore())
                    .environmentObject(memorizationSettings)
            }
            .sheet(isPresented: $showQuickAdd) {
                QuickAddMenuView(
                    isPresented: $showQuickAdd,
                    selectedOption: $quickAddOption,
                    navigationPath: $path,
                    presentedSection: $presentedSection
                )
            }
            .sheet(isPresented: $showTagManagement) {
                NavigationView {
                    TagManagementSettingsView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showTagManagement = false
                                }
                                .foregroundColor(.appGreenDark)
                            }
                        }
                }
                .environmentObject(tagStore)
            }
            .sheet(isPresented: $showSpeakerManagement) {
                NavigationView {
                    SpeakerManagementSettingsView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showSpeakerManagement = false
                                }
                                .foregroundColor(.appGreenDark)
                            }
                        }
                }
                .environmentObject(speakerStore)
            }
            .sheet(isPresented: $showPrayerCategoryManagement) {
                NavigationView {
                    PrayerCategoryManagementSettingsView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showPrayerCategoryManagement = false
                                }
                                .foregroundColor(.appGreenDark)
                            }
                        }
                }
                .environmentObject(getPrayerCategoryStore())
            }
            .tint(Color.appGreenDark)
            .navigationTitle("Christian Life Journal")
            .onChange(of: quickAddOption) { _, newValue in
                guard let option = newValue else { return }
                
                // Navigate directly to the appropriate view
                switch option {
                case .addTag:
                    showTagManagement = true
                case .addSpeaker:
                    showSpeakerManagement = true
                case .addPrayerCategory:
                    showPrayerCategoryManagement = true
                case .addEntry:
                    // Entry selection is now handled directly in QuickAddMenuView
                    break
                }
                
                // Reset the option after handling
                quickAddOption = nil
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: DashboardNav.self) { nav in
                switch nav {
                case .section(let section):
                    if section == .prayerJournal {
                        PrayerDashboardView()
                            .environmentObject(tagStore)
                            .environmentObject(getPrayerRequestStore())
                            .environmentObject(getPrayerCategoryStore())
                    } else {
                        // Route to specific list views instead of generic SectionListView
                        switch section {
                        case .personalTime:
                            PersonalTimeListView()
                                .environmentObject(tagStore)
                        case .sermonNotes:
                            SermonNotesListView()
                                .environmentObject(tagStore)
                                .environmentObject(speakerStore)
                        case .scriptureMemorization:
                            ScriptureMemorizationListView()
                                .environmentObject(tagStore)
                                .environmentObject(memorizationSettings)
                        case .groupNotes:
                            GroupNotesListView()
                                .environmentObject(tagStore)
                                .environmentObject(speakerStore)
                        case .other:
                            OtherListView()
                                .environmentObject(tagStore)
                        case .prayerJournal:
                            // Already handled above
                            EmptyView()
                        case .prayerRequest:
                            PrayerRequestListView()
                                .environmentObject(getPrayerRequestStore())
                                .environmentObject(getPrayerCategoryStore())
                                .environmentObject(tagStore)
                        }
                    }
                case .entryFromSection(let section, let entryUUID):
                    // Find the entry by UUID - shows entry with section context in navigation
                    if let entry = allEntries.first(where: { $0.id == entryUUID }) {
                        JournalEntryDetailView(entry: entry)
                            .environmentObject(tagStore)
                            .environmentObject(speakerStore)
                            .environmentObject(memorizationSettings)
                            .navigationTitle(section.navigationTitle)
                    } else {
                        // Fallback view if entry not found
                        ContentUnavailableView("Entry Not Found", systemImage: "doc.text")
                    }
                case .scriptureEntry(let entryUUID):
                        // Find the scripture entry by UUID
                        if let entry = allScriptureEntries.first(where: { $0.id == entryUUID }) {
                            ScriptureFlashcardView(entry: entry, embedInNavigationView: false)
                                .environmentObject(tagStore)
                                .environmentObject(speakerStore)
                                .environmentObject(memorizationSettings)
                        } else {
                            // Fallback view if scripture entry not found
                            ContentUnavailableView("Scripture Entry Not Found", systemImage: "book.closed")
                        }
                case .prayerRequests:
                    PrayerRequestListView()
                        .environmentObject(getPrayerRequestStore())
                        .environmentObject(getPrayerCategoryStore())
                        .environmentObject(tagStore)
                case .prayerRequest(let requestUUID):
                    // Find the prayer request by UUID
                    if let request = getPrayerRequestStore().prayerRequests.first(where: { $0.id == requestUUID }) {
                        PrayerRequestDetailView(prayerRequest: request)
                            .environmentObject(getPrayerRequestStore())
                            .environmentObject(getPrayerCategoryStore())
                            .environmentObject(tagStore)
                    } else {
                        ContentUnavailableView("Prayer Request Not Found", systemImage: "heart")
                    }
                    
                // MARK: - New Contextual List Views
                case .personalTime:
                    PersonalTimeListView()
                        .environmentObject(tagStore)
                        
                case .sermonNotes:
                    SermonNotesListView()
                        .environmentObject(tagStore)
                        .environmentObject(speakerStore)
                        
                case .scriptureMemorization:
                    ScriptureMemorizationListView()
                        .environmentObject(tagStore)
                        .environmentObject(memorizationSettings)
                        
                case .groupNotes:
                    GroupNotesListView()
                        .environmentObject(tagStore)
                        .environmentObject(speakerStore)
                        
                case .prayerJournal:
                    PrayerJournalListView()
                        .environmentObject(tagStore)
                        
                case .other:
                    OtherListView()
                        .environmentObject(tagStore)
                
                // MARK: - Individual Entry Route
                case .entry(let entryUUID):
                    // Find the entry by UUID
                    if let entry = allEntries.first(where: { $0.id == entryUUID }) {
                        JournalEntryDetailView(entry: entry)
                            .environmentObject(tagStore)
                            .environmentObject(speakerStore)
                            .environmentObject(memorizationSettings)
                    } else {
                        ContentUnavailableView("Entry Not Found", systemImage: "doc.text")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        path.removeAll()
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.appGreenDark)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            // Simplified onChange - no need for complex path clearing since search is now fullScreenCover
            .onAppear {
                path.removeAll()
                
                // Initialize prayer stores if needed
                if prayerRequestStore == nil {
                    prayerRequestStore = PrayerRequestStore(modelContext: modelContext)
                }
                if prayerCategoryStore == nil {
                    prayerCategoryStore = PrayerCategoryStore(modelContext: modelContext)
                }
            }
        }
        .tint(Color.appGreenDark)
    }
    
    private var sectionCards: some View {
        VStack(spacing: 40) {
            ForEach(menuSections, id: \.self) { section in
                sectionCardRow(for: section)
            }
        }
    }
    
    // MARK: - Prayer Store Helpers
    
    private func getPrayerRequestStore() -> PrayerRequestStore {
        if let existingStore = prayerRequestStore {
            return existingStore
        } else {
            let newStore = PrayerRequestStore(modelContext: modelContext)
            prayerRequestStore = newStore
            return newStore
        }
    }
    
    private func getPrayerCategoryStore() -> PrayerCategoryStore {
        if let existingStore = prayerCategoryStore {
            return existingStore
        } else {
            let newStore = PrayerCategoryStore(modelContext: modelContext)
            prayerCategoryStore = newStore
            return newStore
        }
    }
    
    private func sectionCardRow(for section: JournalSection) -> some View {
        CardSectionView(
            section: section,
            prominent: true
        ) {
            // CRITICAL: Ensure path is clear before navigation
            path.removeAll()
            DispatchQueue.main.async {
                // Route to new contextual list views
                switch section {
                case .personalTime:
                    path.append(.personalTime)
                case .sermonNotes:
                    path.append(.sermonNotes)
                case .scriptureMemorization:
                    path.append(.scriptureMemorization)
                case .groupNotes:
                    path.append(.groupNotes)
                case .prayerJournal:
                    path.append(.section(.prayerJournal))
                case .prayerRequest:
                    path.append(.prayerRequests)
                case .other:
                    path.append(.other)
                }
            }
        }
        .frame(height: 56)
    }

    @ViewBuilder
    private func addEntrySheetView(for section: JournalSection) -> some View {
        switch section {
        case .personalTime:
            AddPersonalTimeView(entryToEdit: nil, section: section)
                .environmentObject(tagStore)
                .modelContainer(for: [JournalEntry.self, ScriptureMemoryEntry.self]) // Ensure shared container
        case .sermonNotes:
            AddSermonNotesView(entryToEdit: nil, section: section)
                .environmentObject(tagStore)
                .environmentObject(speakerStore)
                .modelContainer(for: [JournalEntry.self, ScriptureMemoryEntry.self]) // Ensure shared container
        case .scriptureMemorization:
            AddScriptureMemoryView()
                .environmentObject(tagStore)
                .environmentObject(memorizationSettings)
                .environment(\.modelContext, modelContext) // CRITICAL: Pass the same context
                .modelContainer(for: [JournalEntry.self, ScriptureMemoryEntry.self]) // Ensure shared container
        case .prayerRequest:
            AddPrayerRequestView()
                .environmentObject(getPrayerRequestStore())
                .environmentObject(getPrayerCategoryStore())
                .environmentObject(tagStore)
        case .groupNotes:
            AddEntryView(entryToEdit: nil, section: section)
                .environmentObject(tagStore)
                .environmentObject(speakerStore)
                .environment(\.modelContext, modelContext)
        case .prayerJournal:
            AddEntryView(entryToEdit: nil, section: section)
                .environmentObject(tagStore)
                .environment(\.modelContext, modelContext)
        case .other:
            AddEntryView(entryToEdit: nil, section: section)
                .environmentObject(tagStore)
                .environment(\.modelContext, modelContext)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(previewTagStore)
            .environmentObject(previewSpeakerStore)
            .environmentObject(previewMemorizationSettings)
            .modelContainer(previewContainer)
    }
}
