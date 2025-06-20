//
//  QuickAddMenu.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import SwiftUI

struct QuickAddMenu: View {
    let onSelect: (JournalSection) -> Void
    let onCancel: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private let sections: [JournalSection] = [
        .personalTime,
        .scriptureToMemorize,
        .prayerJournal,
        .sermonNotes,
        .groupNotes,
        .other
    ]

    var body: some View {
        VStack {
            Spacer(minLength: 12)
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(sections, id: \.self) { section in
                    MiniCardButton(section: section) {
                        onSelect(section)
                    }
                }
            }
            .padding(.horizontal, 16)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appTan)
    }
}

struct QuickAddMenu_Previews: PreviewProvider {
    static var previews: some View {
        QuickAddMenu(onSelect: { _ in }, onCancel: {})
            .frame(height: 300)
            .background(Color.appTan)
    }
}
