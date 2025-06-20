//
//  MiniCardButton.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import SwiftUI

struct MiniCardButton: View {
    let section: JournalSection
    let action: () -> Void

    private var accentColor: Color {
        switch section {
        case .personalTime: return Color.appGreen
        case .scriptureToMemorize: return Color.appGreen
        case .groupNotes: return Color.appGray
        case .sermonNotes: return Color.appGray
        case .prayerJournal: return Color.appGray
        case .other: return Color.appGray
        }
    }

    var body: some View {
        Button(action: action) {
            Text(section.rawValue)
                .font(.headline)
                .foregroundColor(.appWhite)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 80)
                .background(accentColor)
                .cornerRadius(16)
                .shadow(color: accentColor.opacity(0.18), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
