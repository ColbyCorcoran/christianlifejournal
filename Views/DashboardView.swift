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

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var allEntries: [JournalEntry]
    @State private var addEntry: JournalEntry?
    @State private var path: [JournalEntry] = []
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var showSettings = false
    @State private var settingsPage: SettingsPage = .main
    @StateObject var speakerStore = SpeakerStore()
    @StateObject var tagStore = TagStore()


    private let menuSections: [JournalSection] = [
        .personalTime,
        .scriptureToMemorize,
        .prayerJournal,
        .sermonNotes,
        .groupNotes,
        .other
    ]

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                VStack(spacing: 0) {
                    VStack(spacing: 40) {
                        ForEach(menuSections, id: \.self) { section in
                            CardSectionView(
                                section: section,
                                prominent: true
                            ) {
                                path.append(JournalEntry(section: section.rawValue, title: "", date: Date(), scripture: "", notes: ""))
                            }
                            .frame(height: 56)
                        }
                    }
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
                                Text("Search journal...")
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
                        speakerStore: speakerStore, tagStore: tagStore
                    )
                    .frame(maxWidth: 340)
                    .transition(.scale)
                    .zIndex(2)
                }

            }
            .sheet(item: $addEntry) { entry in
                addEntrySheetView(for: entry)
            }
            .fullScreenCover(isPresented: $showSearch) {
                SearchView(searchText: $searchText, allEntries: allEntries, showSearch: $showSearch)
            }
            .tint(Color.appGreenDark)
            .navigationTitle("Christian Life Journal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: JournalEntry.self) { entry in
                SectionListView(section: JournalSection(rawValue: entry.section) ?? .other)
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
        case .scriptureToMemorize, .prayerJournal, .groupNotes, .other, .none:
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
