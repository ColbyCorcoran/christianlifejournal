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
        case .groupNotes: return Color.appCoral
        case .sermonNotes: return Color.appCoral
        case .prayerJournal: return Color.appCoral
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
                        Text(entry.title)
                            .font(.body)
                            .foregroundColor(.appWhite)
                            .lineLimit(2)
                            .truncationMode(.tail)
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
                section: .scriptureToMemorize,
                entries: [
                    JournalEntry(section: JournalSection.scriptureToMemorize.rawValue, title: "A Very Long Entry Title That Should Truncate If Too Long", date: Date(), bodyText: "Body", scripture: nil, notes: nil, speaker: nil)
                ],
                prominent: false,
                onTap: {}
            )
            CardSectionView(
                section: .personalTime,
                entries: [
                    JournalEntry(section: JournalSection.personalTime.rawValue, title: "Morning Devotion", date: Date(), bodyText: "Body", scripture: nil, notes: nil, speaker: nil)
                ],
                prominent: true,
                onTap: {}
            )
        }
        .padding()
        .background(Color.appTan)
    }
}
