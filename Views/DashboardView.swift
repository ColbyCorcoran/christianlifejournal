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
            ZStack(alignment: .bottomTrailing) {
                GeometryReader { geometry in
                    let topPadding: CGFloat = 32
                    let bottomPadding: CGFloat = 80
                    let buttonHeight: CGFloat = 64 + 32 // button size + bottom padding
                    let cardSpacing: CGFloat = 14
                    let cardCount = CGFloat(menuSections.count)
                    let totalSpacing = cardSpacing * (cardCount - 1)
                    let availableHeight = geometry.size.height - topPadding - bottomPadding - buttonHeight
                    let cardHeight = max((availableHeight - totalSpacing) / cardCount, 44)

                    VStack(spacing: cardSpacing) {
                        ForEach(menuSections, id: \.self) { section in
                            CardSectionView(
                                section: section,
                                prominent: true
                            ) { path.append(section) }
                            .frame(height: cardHeight)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height - buttonHeight,
                        maxHeight: .infinity,
                        alignment: .top
                    )
                    .padding(.top, topPadding)
                    .padding(.horizontal, 20)
                    .padding(.bottom, bottomPadding)
                    .background(Color.appWhite.ignoresSafeArea())
                }
                // Floating Quick Add Button as a Menu
                Menu {
                    ForEach(menuSections.reversed(), id: \.self) { section in
                        Button {
                            addEntrySection = section
                        } label: {
                            Text(section.rawValue)
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(Color.appGreenDark))
                        .shadow(radius: 6)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 32)
                .accessibilityLabel("Quick Add Entry")
            }
            .sheet(item: $addEntrySection) { section in
                addEntrySheetView(for: section)
            }
            .tint(Color.appGreenDark)
            .navigationTitle("Christian Life Journal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: JournalSection.self) { section in
                SectionListView(section: section)
            }
        }
        .tint(Color.appGreenDark)
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
