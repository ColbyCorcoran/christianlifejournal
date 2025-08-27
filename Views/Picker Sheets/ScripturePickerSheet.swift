//
//  ScripturePickerSheet.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/14/25.
//

import SwiftUI

struct ScripturePickerSheet: View {
    @Binding var selectedPassages: [ScripturePassageSelection]
    let allowMultiple: Bool
    @Environment(\.dismiss) private var dismiss
    
    // Initializer with default parameter
    init(selectedPassages: Binding<[ScripturePassageSelection]>, allowMultiple: Bool = true) {
        self._selectedPassages = selectedPassages
        self.allowMultiple = allowMultiple
    }
    
    // Temporary passage being configured in the wheel selector
    @State private var tempPassage: ScripturePassageSelection = ScripturePassageSelection(bookIndex: -1, chapter: 1, verse: 1, verseEnd: 1)
    
    // Temporary selection state
    @State private var temporarySelectedPassages: [ScripturePassageSelection] = []
    
    // Delete confirmation
    @State private var showDeleteAlert = false
    @State private var indexToDelete: Int?

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
        guard tempPassage.bookIndex >= 0 else { return }
        
        if tempPassage.chapter > chapterCount { tempPassage.chapter = chapterCount }
        if tempPassage.verse > verseCount { tempPassage.verse = verseCount }
        if tempPassage.verseEnd > verseCount { tempPassage.verseEnd = verseCount }
        if tempPassage.verseEnd < tempPassage.verse { tempPassage.verseEnd = tempPassage.verse }
    }
    
    private func adjustForChapterChange() {
        guard tempPassage.bookIndex >= 0 else { return }
        
        if tempPassage.verse > verseCount { tempPassage.verse = verseCount }
        if tempPassage.verseEnd > verseCount { tempPassage.verseEnd = verseCount }
        if tempPassage.verseEnd < tempPassage.verse { tempPassage.verseEnd = tempPassage.verse }
    }

    private var formattedPassage: String {
        return tempPassage.displayString(bibleBooks: bibleBooks) ?? "Select Book, Chapter, and Verse"
    }
    
    private func addPassage() {
        guard tempPassage.bookIndex >= 0 else { return }
        guard tempPassage.isValid(bibleBooks: bibleBooks) else { return }
        
        // For single mode, replace existing passage; for multiple mode, check for duplicates
        if allowMultiple {
            // Check if this exact passage already exists
            let exists = temporarySelectedPassages.contains { existing in
                existing.bookIndex == tempPassage.bookIndex &&
                existing.chapter == tempPassage.chapter &&
                existing.verse == tempPassage.verse &&
                existing.verseEnd == tempPassage.verseEnd
            }
            
            if !exists {
                temporarySelectedPassages.append(tempPassage)
                // Reset wheel selector to default
                tempPassage = ScripturePassageSelection(bookIndex: -1, chapter: 1, verse: 1, verseEnd: 1)
            }
        } else {
            // Single mode: replace any existing passage
            temporarySelectedPassages = [tempPassage]
            tempPassage = ScripturePassageSelection(bookIndex: -1, chapter: 1, verse: 1, verseEnd: 1)
        }
    }
    
    private func removePassage(at index: Int) {
        guard index >= 0 && index < temporarySelectedPassages.count else { return }
        temporarySelectedPassages.remove(at: index)
    }
    
    private func applySelection() {
        selectedPassages = temporarySelectedPassages
        dismiss()
    }
    
    private func cancelSelection() {
        dismiss()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Add Passage Card
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Consistent wheel selectors - always show all columns
                        VStack(spacing: 12) {
                            HStack(spacing: 0) {
                                // Book Picker
                                Picker("Book", selection: $tempPassage.bookIndex) {
                                    Text("Book").tag(-1)
                                    ForEach(0..<bibleBooks.count, id: \.self) { idx in
                                        Text(bibleBooks[idx].abbreviations.count > 1 ? bibleBooks[idx].abbreviations[1] : bibleBooks[idx].name).tag(idx)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 100)
                                .clipped()
                                .onChange(of: tempPassage.bookIndex) {
                                    if tempPassage.bookIndex >= 0 && (tempPassage.chapter == 0 || tempPassage.verse == 0) {
                                        tempPassage.chapter = 1
                                        tempPassage.verse = 1
                                        tempPassage.verseEnd = 1
                                    }
                                    adjustForBookChange()
                                }

                                // Chapter Picker - always visible
                                Picker("Chapter", selection: $tempPassage.chapter) {
                                    if tempPassage.bookIndex >= 0 {
                                        ForEach(1...chapterCount, id: \.self) { ch in
                                            Text("\(ch)").tag(ch)
                                        }
                                    } else {
                                        Text("Ch").tag(1)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 70)
                                .clipped()
                                .disabled(tempPassage.bookIndex < 0)
                                .opacity(tempPassage.bookIndex >= 0 ? 1.0 : 0.5)
                                .onChange(of: tempPassage.chapter) {
                                    adjustForChapterChange()
                                }

                                Text(":")
                                    .font(.title2)
                                    .frame(width: 10, alignment: .center)
                                    .opacity(tempPassage.bookIndex >= 0 ? 1.0 : 0.5)

                                // Verse Picker - always visible
                                Picker("Verse", selection: $tempPassage.verse) {
                                    if tempPassage.bookIndex >= 0 {
                                        ForEach(1...verseCount, id: \.self) { v in
                                            Text("\(v)").tag(v)
                                        }
                                    } else {
                                        Text("V").tag(1)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 70)
                                .clipped()
                                .disabled(tempPassage.bookIndex < 0)
                                .opacity(tempPassage.bookIndex >= 0 ? 1.0 : 0.5)
                                .onChange(of: tempPassage.verse) {
                                    if tempPassage.verseEnd < tempPassage.verse {
                                        tempPassage.verseEnd = tempPassage.verse
                                    }
                                }
                                
                                Text("-")
                                    .font(.title2)
                                    .frame(width: 10, alignment: .center)
                                    .opacity(tempPassage.bookIndex >= 0 ? 1.0 : 0.5)

                                // Verse End Picker - always visible
                                Picker("End", selection: $tempPassage.verseEnd) {
                                    if tempPassage.bookIndex >= 0 {
                                        let lower = min(tempPassage.verse, verseCount)
                                        let upper = max(tempPassage.verse, verseCount)
                                        ForEach(lower...upper, id: \.self) { v in
                                            Text("\(v)").tag(v)
                                        }
                                    } else {
                                        Text("End").tag(1)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 70)
                                .clipped()
                                .disabled(tempPassage.bookIndex < 0)
                                .opacity(tempPassage.bookIndex >= 0 ? 1.0 : 0.5)
                            }
                            .frame(height: 120)
                            
                            // Current selection display and add button
                            VStack(spacing: 12) {
                                Text(formattedPassage)
                                    .font(.body)
                                    .foregroundColor(tempPassage.bookIndex >= 0 ? .primary : .secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button(action: addPassage) {
                                    HStack {
                                        Image(systemName: allowMultiple ? "plus.circle.fill" : "checkmark.circle.fill")
                                        Text(allowMultiple ? "Add Passage" : "Select Passage")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(tempPassage.bookIndex >= 0 ? Color.appGreenDark : Color.gray)
                                    )
                                }
                                .disabled(tempPassage.bookIndex < 0)
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    
                    // Selected passages card - only show in multiple mode or when passages exist
                    if allowMultiple {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Selected Passages")
                                .font(.headline)
                                .foregroundColor(.appGreenDark)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(temporarySelectedPassages.indices, id: \.self) { index in
                                    HStack {
                                        Text("• \(temporarySelectedPassages[index].abbreviatedDisplayString(bibleBooks: bibleBooks) ?? "")")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Button(action: { 
                                            indexToDelete = index
                                            showDeleteAlert = true
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.body)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.appGreenPale.opacity(0.3))
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                    } else if !allowMultiple && !temporarySelectedPassages.isEmpty {
                        // Single mode: show current selection in a simpler format
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Current Selection")
                                .font(.headline)
                                .foregroundColor(.appGreenDark)
                            
                            Text(temporarySelectedPassages.first?.displayString(bibleBooks: bibleBooks) ?? "")
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.appGreenPale.opacity(0.3))
                                )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                    }
                    
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color.appWhite.ignoresSafeArea())
            .navigationTitle("Select Scripture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        cancelSelection()
                    }
                    .foregroundColor(.appGreenDark)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applySelection()
                    }
                    .foregroundColor(.appGreenDark)
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Scripture Passage?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let index = indexToDelete {
                        removePassage(at: index)
                        indexToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    indexToDelete = nil
                }
            } message: {
                Text("This will remove the selected Scripture passage from your entry.")
            }
            .onAppear {
                // Initialize temporary selection with current selection
                temporarySelectedPassages = selectedPassages
                
                // Reset temp passage to default when sheet appears
                tempPassage = ScripturePassageSelection(bookIndex: -1, chapter: 1, verse: 1, verseEnd: 1)
            }
        }
    }
}

// MARK: - Preview

struct ScripturePickerSheet_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // Multiple mode preview
            ScripturePickerSheet(selectedPassages: .constant([]), allowMultiple: true)
                .previewDisplayName("Multiple Mode")
            
            // Single mode preview  
            ScripturePickerSheet(selectedPassages: .constant([]), allowMultiple: false)
                .previewDisplayName("Single Mode")
        }
    }
}
