//
//  PassageRow.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/15/25.

import SwiftUI

struct PassageRow: View {
    @Binding var passages: ScripturePassageSelection
    var isLast: Bool
    var onAdd: () -> Void
    var onDelete: () -> Void
    @Binding var isPickerPresented: Bool
    let bibleBooks: [BibleBook]
    var canDelete: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            ScripturePassageSelector(
                bibleBooks: bibleBooks,
                passages: $passages,
                isPickerPresented: $isPickerPresented,
                label: "Scripture Passage"
            )
            if canDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            }
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

