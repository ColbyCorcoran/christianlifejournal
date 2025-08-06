//
//  DashboardView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.

import SwiftUI
import SwiftData

enum SettingsPage {
    case main
    case sectionControls
    case userExperienceControls
    case appInformation
    case tagManagement
    case speakerManagement
    case scriptureMemorization
}

enum DashboardNav: Hashable {
    case section(JournalSection)
    case entry(UUID) // Use UUID instead of JournalEntry
    case scriptureEntry(UUID)
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
    @State private var settingsPage: SettingsPage = .main
    
    @State private var presentedSection: IdentifiableSection?

    @EnvironmentObject var speakerStore: SpeakerStore
    @EnvironmentObject var tagStore: TagStore
    @StateObject private var memorizationSettings = MemorizationSettings()

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
                                Text("Search entries...")
                                    .foregroundColor(.appGreenDark.opacity(0.7))
                                    .font(.body)
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.appGreenPale)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Menu {
                            ForEach(menuSections.reversed(), id: \.self) { section in
                                Button {
                                    // CRITICAL: Clear path before presenting sheet
                                    path.removeAll()
                                    presentedSection = IdentifiableSection(section: section)
                                } label: {
                                    Text(section.rawValue)
                                }
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.appGreenDark))
                                .shadow(radius: 3)
                        }
                        .accessibilityLabel("Quick Add Entry")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color.appWhite.ignoresSafeArea())

                // Settings overlay
                if showSettings {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .onTapGesture {
                            path.removeAll()
                            showSettings = false
                            settingsPage = .main
                        }

                    SettingsMenuView(
                        isPresented: $showSettings,
                        settingsPage: $settingsPage
                    )
                    .environmentObject(tagStore)
                    .environmentObject(speakerStore)
                    .environmentObject(memorizationSettings)
                    .frame(maxWidth: 340)
                    .transition(.scale)
                    .zIndex(2)
                }
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
                    selectedSpeakers: $selectedSpeakers
                )
                .environmentObject(tagStore)
                .environmentObject(speakerStore)
                .interactiveDismissDisabled() // Prevent accidental dismissal
            }
            .tint(Color.appGreenDark)
            .navigationTitle("Christian Life Journal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: DashboardNav.self) { nav in
                switch nav {
                case .section(let section):
                    SectionListView(section: section)
                        .environmentObject(tagStore)
                        .environmentObject(speakerStore)
                        .environmentObject(memorizationSettings)
                case .entry(let entryUUID):
                    // Find the entry by UUID
                    if let entry = allEntries.first(where: { $0.id == entryUUID }) {
                        JournalEntryDetailView(entry: entry)
                            .environmentObject(tagStore)
                            .environmentObject(speakerStore)
                            .environmentObject(memorizationSettings)
                    } else {
                        // Fallback view if entry not found
                        ContentUnavailableView("Entry Not Found", systemImage: "doc.text")
                    }
                case .scriptureEntry(let entryUUID):
                        // Find the scripture entry by UUID
                        if let entry = allScriptureEntries.first(where: { $0.id == entryUUID }) {
                            ScriptureFlashcardView(entry: entry)
                                .environmentObject(tagStore)
                                .environmentObject(speakerStore)
                                .environmentObject(memorizationSettings)
                        } else {
                            // Fallback view if scripture entry not found
                            ContentUnavailableView("Scripture Entry Not Found", systemImage: "book.closed")
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
            }
        }
        .id(navigationKey) // Force NavigationStack recreation
        .tint(Color.appGreenDark)
    }
    
    private var sectionCards: some View {
        VStack(spacing: 40) {
            ForEach(menuSections, id: \.self) { section in
                sectionCardRow(for: section)
            }
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
                path.append(.section(section))
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
        case .sermonNotes:
            AddSermonNotesView(entryToEdit: nil, section: section)
                .environmentObject(tagStore)
                .environmentObject(speakerStore)
        case .scriptureMemorization:
            AddScriptureMemoryView()
                .environmentObject(tagStore)
                .environmentObject(memorizationSettings)
        case .prayerJournal, .groupNotes, .other:
            AddEntryView(entryToEdit: nil, section: section)
                .environmentObject(tagStore)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(TagStore())
            .environmentObject(SpeakerStore())
            .modelContainer(for: [JournalEntry.self, ScriptureMemoryEntry.self], inMemory: true)
    }
}
