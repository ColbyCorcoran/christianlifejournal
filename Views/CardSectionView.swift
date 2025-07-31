//
//  CardSectionView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import SwiftUI

struct CardSectionView: View {
    let section: JournalSection
    let prominent: Bool
    let onTap: () -> Void

    // Assign a unique green for each section
    private var accentColor: Color {
        switch section {
        case .personalTime:         return .appGreenDark
        case .scriptureMemorization:  return .appGreen
        case .prayerJournal:        return .appGreenMedium
        case .sermonNotes:          return .appGreenMid
        case .groupNotes:           return .appGreenLight
        case .other:                return .appGreenPale
        }
    }

    // All cards are the same height, skinnier than before
    private var cardHeight: CGFloat { 70 }

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(section.rawValue)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1) // <-- Text shadow for readability
                    .padding(.leading, 20)
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight, alignment: .leading)
            .background(accentColor)
            .cornerRadius(18)
            .shadow(color: accentColor.opacity(0.12), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight)
        .padding(.vertical, 2)
    }
}

struct CardSectionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            ForEach(JournalSection.allCases, id: \.self) { section in
                CardSectionView(section: section, prominent: true, onTap: {})
                    .frame(height: 56)
            }
        }
        .padding()
        .background(Color.appWhite)
    }
}
