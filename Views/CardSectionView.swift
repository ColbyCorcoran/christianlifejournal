//
//  CardSectionView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import SwiftUI

struct CardSectionView: View {
    let section: JournalSection
    let entries: [JournalEntry]
    let prominent: Bool
    let onTap: () -> Void

    private var accentColor: Color {
        switch section {
        case .personalTime: return Color.appGreen
        case .scriptureToMemorize: return Color.appGreen
        case .groupNotes: return Color.appBrown
        case .sermonNotes: return Color.appBlue
        case .prayerJournal: return Color.appTanLight
        case .other: return Color.appCoral
        }
    }

    private var cardHeight: CGFloat { prominent ? 200 : 150 }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                Text(section.rawValue)
                    .font(prominent ? .title2.bold() : .title3.bold())
                    .foregroundColor(.appWhite)
                    .fixedSize(horizontal: false, vertical: true)
                if let entry = entries.first {
                    VStack(alignment: .leading, spacing: 4) {
                        if section == .personalTime {
                            // Show scripture passages instead of title
                            if let scripture = entry.scripture, !scripture.isEmpty {
                                ForEach(scripture.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }, id: \.self) { passage in
                                    Text(passage)
                                        .font(.body)
                                        .foregroundColor(.appWhite)
                                        .lineLimit(2)
                                        .truncationMode(.tail)
                                }
                            } else {
                                Text("No scripture passage")
                                    .font(.body)
                                    .foregroundColor(.appWhite)
                            }
                        } else {
                            Text(entry.title)
                                .font(.body)
                                .foregroundColor(.appWhite)
                                .lineLimit(2)
                                .truncationMode(.tail)
                        }
                        Text(formattedDate(entry.date))
                            .font(.caption)
                            .foregroundColor(.appWhite)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                } else {
                    Text("No entries yet")
                        .font(.caption)
                        .foregroundColor(.appWhite)
                }
                Spacer()
            }
            .padding(prominent ? 32 : 20)
            .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight, alignment: .leading)
            .background(accentColor)
            .cornerRadius(24)
            .shadow(color: accentColor.opacity(0.18), radius: prominent ? 14 : 10, x: 0, y: 6)
            .clipped()
        }
        .buttonStyle(PlainButtonStyle())
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight)
    }
}

struct CardSectionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            CardSectionView(
                section: .personalTime,
                entries: [
                    JournalEntry(section: JournalSection.personalTime.rawValue, title: "", date: Date(), bodyText: nil, scripture: "John 3:16; Psalm 23:1", notes: nil, speaker: nil)
                ],
                prominent: true,
                onTap: {}
            )
            CardSectionView(
                section: .sermonNotes,
                entries: [
                    JournalEntry(section: JournalSection.sermonNotes.rawValue, title: "Sunday Sermon", date: Date(), bodyText: nil, scripture: nil, notes: nil, speaker: nil)
                ],
                prominent: false,
                onTap: {}
            )
        }
        .padding()
        .background(Color.appTan)
    }
}
