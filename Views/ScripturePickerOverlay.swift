//
//  ScripturePickerOverlay.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/20/25.
//

import SwiftUI

struct ScripturePickerOverlay: View {
    let bibleBooks: [BibleBook]
    @Binding var isPresented: Bool
    @Binding var passages: ScripturePassageSelection
    
    // Temporary selections that get applied when user taps checkmark
    @State private var tempPassage: ScripturePassageSelection = ScripturePassageSelection(bookIndex: -1, chapter: 1, verse: 1, verseEnd: 1)

    // Safe computed properties that handle default state
    var selectedBook: BibleBook? {
        guard tempPassage.bookIndex >= 0 && tempPassage.bookIndex < bibleBooks.count else { return nil }
        return bibleBooks[tempPassage.bookIndex]
    }
    
    var chapterCount: Int {
        guard let book = selectedBook else { return 1 }
        return max(book.chapters.count, 1)
    }
    
    var verseCount: Int {
        guard let book = selectedBook else { return 1 }
        let chapterIndex = tempPassage.chapter - 1
        guard chapterIndex >= 0 && chapterIndex < book.chapters.count else { return 1 }
        return max(book.chapters[chapterIndex], 1)
    }

    private func adjustForBookChange() {
        // Only adjust if we have a valid book selected
        guard tempPassage.bookIndex >= 0 else { return }
        
        if tempPassage.chapter > chapterCount { tempPassage.chapter = chapterCount }
        if tempPassage.verse > verseCount { tempPassage.verse = verseCount }
        if tempPassage.verseEnd > verseCount { tempPassage.verseEnd = verseCount }
        if tempPassage.verseEnd < tempPassage.verse { tempPassage.verseEnd = tempPassage.verse }
    }
    
    private func adjustForChapterChange() {
        // Only adjust if we have a valid book selected
        guard tempPassage.bookIndex >= 0 else { return }
        
        if tempPassage.verse > verseCount { tempPassage.verse = verseCount }
        if tempPassage.verseEnd > verseCount { tempPassage.verseEnd = verseCount }
        if tempPassage.verseEnd < tempPassage.verse { tempPassage.verseEnd = tempPassage.verse }
    }

    private var formattedPassage: String {
        // Use the existing displayString method or default
        return tempPassage.displayString(bibleBooks: bibleBooks) ?? "Scripture Passage"
    }
    
    private func applySelection() {
        passages = tempPassage
    }
    
    private func cancelSelection() {
        isPresented = false
    }
    
    private func confirmSelection() {
        if tempPassage.bookIndex >= 0 {
            applySelection()
        }
        isPresented = false
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture { cancelSelection() }

            VStack(spacing: 18) {
                // Header with title and buttons
                ZStack {
                    Text("Select Scripture")
                        .font(.headline)
                    
                    HStack {
                        // Cancel button (gray X)
                        Button(action: cancelSelection) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Confirm button (green checkmark)
                        Button(action: confirmSelection) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.appGreenDark)
                        }
                    }
                }
                .padding(.top, 8)

                // Scripture picker content
                VStack(spacing: 12) {
                    HStack(spacing: 0) {
                        // Book Picker
                        Picker("Book", selection: $tempPassage.bookIndex) {
                            // Add default option
                            Text("Select Book").tag(-1)
                            
                            ForEach(0..<bibleBooks.count, id: \.self) { idx in
                                Text(bibleBooks[idx].name).tag(idx)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 160)
                        .clipped()
                        .onChange(of: tempPassage.bookIndex) {
                            // Reset to default values when a book is first selected
                            if tempPassage.bookIndex >= 0 && (tempPassage.chapter == 0 || tempPassage.verse == 0) {
                                tempPassage.chapter = 1
                                tempPassage.verse = 1
                                tempPassage.verseEnd = 1
                            }
                            adjustForBookChange()
                        }

                        // Chapter Picker - only show if book is selected
                        if tempPassage.bookIndex >= 0 {
                            Picker("Chapter", selection: $tempPassage.chapter) {
                                ForEach(1...chapterCount, id: \.self) { ch in
                                    Text("\(ch)").tag(ch)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            .clipped()
                            .onChange(of: tempPassage.chapter) {
                                adjustForChapterChange()
                            }

                            // Colon between chapter and verse
                            Text(":")
                                .font(.title2)
                                .frame(width: 8, alignment: .center)

                            // Verse Picker
                            Picker("Verse", selection: $tempPassage.verse) {
                                ForEach(1...verseCount, id: \.self) { v in
                                    Text("\(v)").tag(v)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            .clipped()
                            .onChange(of: tempPassage.verse) {
                                if tempPassage.verseEnd < tempPassage.verse {
                                    tempPassage.verseEnd = tempPassage.verse
                                }
                            }
                            
                            // Dash between verse and verse end
                            Text("-")
                                .font(.title2)
                                .frame(width: 8, alignment: .center)

                            // Verse End Picker (for range)
                            Picker("Verse End", selection: $tempPassage.verseEnd) {
                                let lower = min(tempPassage.verse, verseCount)
                                let upper = max(tempPassage.verse, verseCount)
                                ForEach(lower...upper, id: \.self) { v in
                                    Text("\(v)").tag(v)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            .clipped()
                        } else {
                            // Placeholder views when no book is selected
                            Text("Select a book first")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(width: 200, height: 120)
                        }
                    }
                    .frame(height: 160)

                    // Display the selected passage
                    Text(formattedPassage)
                        .font(.title3)
                        .foregroundColor(tempPassage.bookIndex >= 0 ? .primary : .gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .background(Color.appWhite)
                .cornerRadius(10)
            }
            .padding()
            .frame(width: 370, height: 280)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.appWhite)
                    .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
            )
            .onAppear {
                // Always initialize with the current passage value
                tempPassage = passages
            }
            .onChange(of: isPresented) { _, newValue in
                // Reset tempPassage whenever the picker is presented
                if newValue {
                    tempPassage = passages
                }
            }
        }
    }
}

struct ScripturePickerOverlay_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with default state (no selection)
        ScripturePickerOverlay(
            bibleBooks: bibleBooks,
            isPresented: .constant(true),
            passages: .constant(ScripturePassageSelection(bookIndex: -1, chapter: 1, verse: 1, verseEnd: 1))
        )
        .previewDisplayName("Default State")
        
        // Preview with selection
        ScripturePickerOverlay(
            bibleBooks: bibleBooks,
            isPresented: .constant(true),
            passages: .constant(ScripturePassageSelection(bookIndex: 0, chapter: 1, verse: 1, verseEnd: 1))
        )
        .previewDisplayName("With Selection")
    }
}
