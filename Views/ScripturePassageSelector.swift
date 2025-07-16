//
//  ScripturePassageSelector.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/15/25.
//

import SwiftUI

struct ScripturePassageSelector: View {
    let bibleBooks: [BibleBook]
    @Binding var passage: ScripturePassageSelection
    @Binding var isPickerPresented: Bool
    var label: String = "Select Passage"

    var body: some View {
        Button(action: { isPickerPresented = true }) {
            HStack {
                Text(passage.displayString(bibleBooks: bibleBooks) ?? label)
                    .foregroundColor(passage.isValid(bibleBooks: bibleBooks) ? .primary : .red)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundColor(.appGreenDark)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.appGreenPale))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Data structure for a single passage selection
struct ScripturePassageSelection: Equatable {
    var bookIndex: Int
    var chapter: Int
    var verse: Int
    var verseEnd: Int

    func displayString(bibleBooks: [BibleBook]) -> String? {
        guard bookIndex < bibleBooks.count else { return nil }
        let book = bibleBooks[bookIndex].name
        if verseEnd > verse {
            return "\(book) \(chapter):\(verse)-\(verseEnd)"
        } else {
            return "\(book) \(chapter):\(verse)"
        }
    }

    func isValid(bibleBooks: [BibleBook]) -> Bool {
        guard bookIndex < bibleBooks.count else { return false }
        let book = bibleBooks[bookIndex]
        guard chapter >= 1, chapter <= book.chapters.count else { return false }
        let maxVerse = book.chapters[chapter - 1]
        guard verse >= 1, verse <= maxVerse else { return false }
        guard verseEnd >= verse, verseEnd <= maxVerse else { return false }
        return true
    }
}

