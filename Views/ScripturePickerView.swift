//
//  ScripturePickerView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/15/25.
//

import SwiftUI

struct ScripturePickerView: View {
    let bibleBooks: [BibleBook]
    @Binding var selectedBookIndex: Int // -1 for "no selection"
    @Binding var selectedChapter: Int
    @Binding var selectedVerse: Int
    @Binding var selectedVerseEnd: Int

    // Safe computed properties that handle default state
    var selectedBook: BibleBook? {
        guard selectedBookIndex >= 0 && selectedBookIndex < bibleBooks.count else { return nil }
        return bibleBooks[selectedBookIndex]
    }
    
    var chapterCount: Int {
        guard let book = selectedBook else { return 1 }
        return max(book.chapters.count, 1)
    }
    
    var verseCount: Int {
        guard let book = selectedBook else { return 1 }
        let chapterIndex = selectedChapter - 1
        guard chapterIndex >= 0 && chapterIndex < book.chapters.count else { return 1 }
        return max(book.chapters[chapterIndex], 1)
    }

    private func adjustForBookChange() {
        // Only adjust if we have a valid book selected
        guard selectedBookIndex >= 0 else { return }
        
        if selectedChapter > chapterCount { selectedChapter = chapterCount }
        if selectedVerse > verseCount { selectedVerse = verseCount }
        if selectedVerseEnd > verseCount { selectedVerseEnd = verseCount }
        if selectedVerseEnd < selectedVerse { selectedVerseEnd = selectedVerse }
    }
    
    private func adjustForChapterChange() {
        // Only adjust if we have a valid book selected
        guard selectedBookIndex >= 0 else { return }
        
        if selectedVerse > verseCount { selectedVerse = verseCount }
        if selectedVerseEnd > verseCount { selectedVerseEnd = verseCount }
        if selectedVerseEnd < selectedVerse { selectedVerseEnd = selectedVerse }
    }

    private var formattedPassage: String {
        // Handle default state
        guard selectedBookIndex >= 0, let book = selectedBook else {
            return "Scripture Passage"
        }
        
        if selectedVerseEnd > selectedVerse {
            return "\(book.name) \(selectedChapter):\(selectedVerse)-\(selectedVerseEnd)"
        } else {
            return "\(book.name) \(selectedChapter):\(selectedVerse)"
        }
    }

    var body: some View {
        ZStack {
            Color.appWhite.ignoresSafeArea()

            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    // Book Picker
                    Picker("Book", selection: $selectedBookIndex) {
                        // Add default option
                        Text("Select Book").tag(-1)
                        
                        ForEach(0..<bibleBooks.count, id: \.self) { idx in
                            Text(bibleBooks[idx].name).tag(idx)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 140)
                    .clipped()
                    .onChange(of: selectedBookIndex) {
                        // Reset to default values when a book is first selected
                        if selectedBookIndex >= 0 && (selectedChapter == 0 || selectedVerse == 0) {
                            selectedChapter = 1
                            selectedVerse = 1
                            selectedVerseEnd = 1
                        }
                        adjustForBookChange()
                    }

                    // Chapter Picker - only show if book is selected
                    if selectedBookIndex >= 0 {
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

                        // Colon between chapter and verse
                        Text(":")
                            .font(.title2)
                            .frame(width: 5, alignment: .center)

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
                        
                        // Dash between verse and verse end
                        Text("-")
                            .font(.title2)
                            .frame(width: 5, alignment: .center)

                        // Verse End Picker (for range)
                        Picker("Verse End", selection: $selectedVerseEnd) {
                            let lower = min(selectedVerse, verseCount)
                            let upper = max(selectedVerse, verseCount)
                            ForEach(lower...upper, id: \.self) { v in
                                Text("\(v)").tag(v)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        .clipped()
                    } else {
                        // Placeholder views when no book is selected
                        Text("Select a book first")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(width: 250, height: 180)
                    }
                }
                .frame(height: 180)
                .background(Color.appWhite)

                // Display the selected passage
                Text(formattedPassage)
                    .font(.title2)
                    .foregroundColor(selectedBookIndex >= 0 ? .primary : .gray)
                    .padding(.top, 12)
            }
            .padding(.bottom, 8)
        }
    }
}

struct ScripturePickerView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with default state (no selection)
        ScripturePickerView(
            bibleBooks: bibleBooks,
            selectedBookIndex: .constant(-1), // -1 for default state
            selectedChapter: .constant(1),
            selectedVerse: .constant(1),
            selectedVerseEnd: .constant(1)
        )
        .previewDisplayName("Default State")
        
        // Preview with selection
        ScripturePickerView(
            bibleBooks: bibleBooks,
            selectedBookIndex: .constant(0),
            selectedChapter: .constant(1),
            selectedVerse: .constant(1),
            selectedVerseEnd: .constant(1)
        )
        .previewDisplayName("With Selection")
    }
}
