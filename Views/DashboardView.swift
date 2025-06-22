//
//  DashboardView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var allEntries: [JournalEntry]
    @State private var addEntrySection: JournalSection?
    @State private var path: [JournalSection] = []

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // Custom order for menu and dashboard
    private let menuSections: [JournalSection] = [
        .other,
        .groupNotes,
        .sermonNotes,
        .prayerJournal,
        .scriptureToMemorize,
        .personalTime
    ]

    private func entries(for section: JournalSection) -> [JournalEntry] {
        allEntries.filter { $0.section == section.rawValue }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 20) {
                        CardSectionView(
                            section: .personalTime,
                            entries: entries(for: .personalTime),
                            prominent: true
                        ) { path.append(.personalTime) }
                        CardSectionView(
                            section: .scriptureToMemorize,
                            entries: entries(for: .scriptureToMemorize),
                            prominent: true
                        ) { path.append(.scriptureToMemorize) }
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach([JournalSection.prayerJournal, .sermonNotes, .groupNotes, .other], id: \.self) { section in
                                CardSectionView(
                                    section: section,
                                    entries: entries(for: section),
                                    prominent: false
                                ) { path.append(section) }
                                .frame(height: 140)
                            }
                        }
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 80)
                }
                .background(Color.appWhite.ignoresSafeArea())
                // Floating Quick Add Button as a Menu
                Menu {
                    ForEach(menuSections, id: \.self) { section in
                        Button {
                            addEntrySection = section
                        } label: {
                            Text(section.rawValue)
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.appWhite)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(Color.appBlue))
                        .shadow(radius: 6)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 32)
                .accessibilityLabel("Quick Add Entry")
            }
            .sheet(item: $addEntrySection) { section in
                addEntrySheetView(for: section)
            }
            .tint(Color.appBlue)
            .navigationTitle("Christian Life Journal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: JournalSection.self) { section in
                SectionListView(section: section)
            }
        }
        .tint(Color.appBlue)
    }

    @ViewBuilder
    private func addEntrySheetView(for section: JournalSection) -> some View {
        switch section {
        case .prayerJournal, .groupNotes, .other:
            AddEntryView(section: section)
        case .personalTime:
            AddPersonalTimeView()
        case .sermonNotes:
            AddSermonNotesView()
        case .scriptureToMemorize:
            AddScriptureToMemorizeView()
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .modelContainer(for: JournalEntry.self, inMemory: true)
    }
}
