//
//  ScripturePickerView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/15/25.
//

import SwiftUI

struct ScripturePickerView: View {
    let bibleBooks: [BibleBook]
    @Binding var selectedBookIndex: Int
    @Binding var selectedChapter: Int
    @Binding var selectedVerse: Int
    @Binding var selectedVerseEnd: Int

    var selectedBook: BibleBook { bibleBooks[selectedBookIndex] }
    var chapterCount: Int { max(selectedBook.chapters.count, 1) }
    var verseCount: Int { max(selectedBook.chapters[safe: selectedChapter - 1] ?? 1, 1) }

    private func adjustForBookChange() {
        if selectedChapter > chapterCount { selectedChapter = chapterCount }
        if selectedVerse > verseCount { selectedVerse = verseCount }
        if selectedVerseEnd > verseCount { selectedVerseEnd = verseCount }
        if selectedVerseEnd < selectedVerse { selectedVerseEnd = selectedVerse }
    }
    private func adjustForChapterChange() {
        if selectedVerse > verseCount { selectedVerse = verseCount }
        if selectedVerseEnd > verseCount { selectedVerseEnd = verseCount }
        if selectedVerseEnd < selectedVerse { selectedVerseEnd = selectedVerse }
    }

    private var formattedPassage: String {
        guard selectedBookIndex < bibleBooks.count else { return "" }
        let book = bibleBooks[selectedBookIndex].name
        if selectedVerseEnd > selectedVerse {
            return "\(book) \(selectedChapter):\(selectedVerse)-\(selectedVerseEnd)"
        } else {
            return "\(book) \(selectedChapter):\(selectedVerse)"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                // Book Picker
                Picker("Book", selection: $selectedBookIndex) {
                    ForEach(0..<bibleBooks.count, id: \.self) { idx in
                        Text(bibleBooks[idx].name).tag(idx)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 140)
                .clipped()
                .onChange(of: selectedBookIndex) {
                    adjustForBookChange()
                }

                // Chapter Picker
                Picker("Chapter", selection: $selectedChapter) {
                    ForEach(1...chapterCount, id: \.self) { ch in
                        Text("\(ch)").tag(ch)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
                .clipped()
                .onChange(of: selectedChapter) {
                    adjustForChapterChange()
                }

                // Verse Picker
                Picker("Verse", selection: $selectedVerse) {
                    ForEach(1...verseCount, id: \.self) { v in
                        Text("\(v)").tag(v)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
                .clipped()
                .onChange(of: selectedVerse) {
                    if selectedVerseEnd < selectedVerse {
                        selectedVerseEnd = selectedVerse
                    }
                }

                // Verse End Picker (for range)
                Picker("Verse End", selection: $selectedVerseEnd) {
                    ForEach(selectedVerse...verseCount, id: \.self) { v in
                        Text("\(v)").tag(v)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
                .clipped()
            }
            .frame(height: 180)
            

            // Display the selected passage
            Text(formattedPassage)
                .font(.title2)
                .foregroundColor(.appGreenDark)
                .padding(.top, 8)
                .padding(.bottom, 12)
        }
        .background(Color.appWhite)
        .padding(.bottom, 8)
    }
}

// MARK: - Safe Array Indexing Helper
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct ScripturePickerView_Previews: PreviewProvider {
    static var previews: some View {
        ScripturePickerView(
            bibleBooks: bibleBooks,
            selectedBookIndex: .constant(0),
            selectedChapter: .constant(1),
            selectedVerse: .constant(1),
            selectedVerseEnd: .constant(1)
        )
    }
}
