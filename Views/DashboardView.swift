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
    case entry(JournalEntry)
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var allEntries: [JournalEntry]
    @State private var addEntry: JournalEntry?
    @State private var path: [DashboardNav] = []
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var showSettings = false
    @State private var settingsPage: SettingsPage = .main
    @State private var isNewEntry: Bool = false

    @StateObject var speakerStore = SpeakerStore()
    @StateObject var tagStore = TagStore()

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
    
    private func sectionCardRow(for section: JournalSection) -> some View {
        CardSectionView(
            section: section,
            prominent: true
        ) {
            path.append(.section(section))
        }
        .frame(height: 56)
    }
    
    private var sectionCards: some View {
        VStack(spacing: 40) {
            ForEach(menuSections, id: \.self) { section in
                sectionCardRow(for: section)
            }
        }
    }


    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                VStack(spacing: 0) {
                    sectionCards
                    .padding(.top, 32)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 0)

                    Spacer(minLength: 0)

                    // Search bar and quick add button inline at the bottom
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
                                    let newEntry = JournalEntry(
                                        section: section.rawValue,
                                        title: "",
                                        date: Date(),
                                        scripture: "",
                                        notes: ""
                                    )
                                    modelContext.insert(newEntry)
                                    addEntry = newEntry
                                    isNewEntry = true
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

                // Centered overlay settings menu
                if showSettings {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .onTapGesture { showSettings = false; settingsPage = .main }

                    SettingsMenuView(
                        isPresented: $showSettings,
                        settingsPage: $settingsPage,
                        speakerStore: speakerStore,
                        tagStore: tagStore
                    )
                    .frame(maxWidth: 340)
                    .transition(.scale)
                    .zIndex(2)
                }

                // Centered overlay search view
                if showSearch {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .onTapGesture { showSearch = false }

                    SearchView(
                        searchText: $searchText,
                        allEntries: allEntries,
                        showSearch: $showSearch,
                        tagStore: tagStore,
                        speakerStore: speakerStore,
                        selectedTagIDs: $selectedTagIDs,
                        selectedBooks: $selectedBooks,
                        selectedSections: $selectedSections,
                        selectedSpeakers: $selectedSpeakers
                    )
                    .frame(maxWidth: 400, maxHeight: .infinity)
                    .zIndex(3)
                }
            }
            .sheet(item: $addEntry) { entry in
                addEntrySheetView(for: entry)
            }
            .tint(Color.appGreenDark)
            .navigationTitle("Christian Life Journal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: DashboardNav.self) { nav in
                switch nav {
                case .section(let section):
                    SectionListView(section: section)
                case .entry(let entry):
                    JournalEntryDetailView(entry: entry)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.appGreenDark)
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
        .tint(Color.appGreenDark)
    }

    @ViewBuilder
    private func addEntrySheetView(for entry: JournalEntry) -> some View {
        switch JournalSection(rawValue: entry.section) {
        case .personalTime:
            AddPersonalTimeView(entryToEdit: entry, tagStore: tagStore)
        case .sermonNotes:
            AddSermonNotesView(entryToEdit: entry, speakerStore: speakerStore, tagStore: tagStore)
        case .scriptureMemorization, .prayerJournal, .groupNotes, .other, .none:
            AddEntryView(entryToEdit: entry, tagStore: tagStore)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .modelContainer(for: JournalEntry.self, inMemory: true)
    }
}
