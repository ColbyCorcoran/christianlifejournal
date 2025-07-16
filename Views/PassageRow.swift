//
//  PassageRow.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/15/25.
//

import SwiftUI

struct PassageRow: View {
    @Binding var passage: ScripturePassageSelection
    var isLast: Bool
    var onAdd: () -> Void
    @Binding var isPickerPresented: Bool
    let bibleBooks: [BibleBook]

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            ScripturePassageSelector(
                bibleBooks: bibleBooks,
                passage: $passage,
                isPickerPresented: $isPickerPresented,
                label: "Select Passage"
            )
            if isLast {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.appGreenDark)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale)
            }
        }
    }
}

