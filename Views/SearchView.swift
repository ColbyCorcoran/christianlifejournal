//
//  SearchView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/11/25.
//

import SwiftUI

struct SearchView: View {
    @Binding var searchText: String
    let allEntries: [JournalEntry]
    @Binding var showSearch: Bool
    @ObservedObject var tagStore: TagStore
    @ObservedObject var speakerStore: SpeakerStore

    @Binding var selectedTagIDs: Set<UUID>
    @Binding var selectedBooks: Set<String>
    @Binding var selectedSections: Set<String>
    @Binding var selectedSpeakers: Set<String>

    @FocusState private var isSearchFocused: Bool
    @State private var searchNavPath: [JournalEntry] = []

    var filteredEntries: [JournalEntry] {
        allEntries.filter { entry in
            // Text search
            let matchesText = searchText.isEmpty ||
                entry.title.lowercased().contains(searchText.lowercased()) ||
                (entry.scripture?.lowercased().contains(searchText.lowercased()) ?? false) ||
                (entry.notes?.lowercased().contains(searchText.lowercased()) ?? false)

            // Bible book filter
            let matchesBook = selectedBooks.isEmpty ||
                (entry.scripture?.split(separator: ";").contains(where: { passage in
                    selectedBooks.contains(where: { book in passage.trimmingCharacters(in: .whitespaces).hasPrefix(book) })
                }) ?? false)

            // Section filter
            let matchesSection = selectedSections.isEmpty ||
                selectedSections.contains(JournalSection(rawValue: entry.section)?.displayName ?? "")

            // Speaker filter
            let matchesSpeaker = selectedSpeakers.isEmpty ||
                selectedSpeakers.contains(entry.speaker ?? "")

            // Tag filter
            let matchesTag = selectedTagIDs.isEmpty ||
            !(Set(entry.tagIDs).isDisjoint(with: selectedTagIDs))

            return matchesText && matchesBook && matchesSection && matchesSpeaker && matchesTag
        }
    }
    
    private func resetSearchParameters() {
        searchText = ""
        selectedTagIDs = []
        selectedBooks = []
        selectedSections = []
        selectedSpeakers = []
    }


    var body: some View {
        NavigationStack(path: $searchNavPath) {
            VStack(spacing: 0) {
                
                Group {
                    if searchText.isEmpty && selectedTagIDs.isEmpty && selectedBooks.isEmpty && selectedSections.isEmpty && selectedSpeakers.isEmpty {
                        Spacer()
                        Text("Type to search your entries.")
                            .foregroundColor(.appGreen)
                            .font(.body)
                        Spacer()
                    } else if filteredEntries.isEmpty {
                        Spacer()
                        Text("No results found.")
                            .foregroundColor(.appGreen)
                            .font(.body)
                        Spacer()
                    } else {
                        List(filteredEntries) { entry in
                            NavigationLink(value: entry) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.title.isEmpty ? (entry.scripture ?? "Untitled") : entry.title)
                                        .font(.headline)
                                    Text(formattedDate(entry.date))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.appWhite)
                    }
                }
                .frame(maxHeight: .infinity)
                
                HStack(spacing: 12) {
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

                    FilterButton<String>(
                        label: "Speakers",
                        selected: selectedSpeakers,
                        options: speakerStore.speakers,
                        displayName: { $0 },
                        onSelect: { speaker in
                            if selectedSpeakers.contains(speaker) {
                                selectedSpeakers.remove(speaker)
                            } else {
                                selectedSpeakers.insert(speaker)
                            }
                        }
                    )

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
                }
                .padding(.horizontal)
                .padding(.top, 8)

                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.appGreenDark)
                        TextField("Search entries...", text: $searchText)
                            .focused($isSearchFocused)
                            .submitLabel(.search)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.appGreenPale)
                    )

                    Button(action: {
                        resetSearchParameters()
                        showSearch = false
                    }) {
                        Text("Cancel")
                            .foregroundColor(.appGreenDark)
                            .padding(.leading, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 32)
            }
            .background(Color.appWhite.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: JournalEntry.self) { entry in
                JournalEntryDetailView(entry: entry)
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
            tagStore: TagStore(),
            speakerStore: SpeakerStore(),
            selectedTagIDs: .constant([]),
            selectedBooks: .constant([]),
            selectedSections: .constant([]),
            selectedSpeakers: .constant([])
        )
    }
}
