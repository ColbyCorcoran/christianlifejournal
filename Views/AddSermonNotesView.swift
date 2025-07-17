//
//  AddSermonNotesView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import SwiftUI
import SwiftData

struct AddSermonNotesView: View {
    @Environment(\.modelContext) private var modelContext
    var entryToEdit: JournalEntry? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @FocusState private var isTitleFocused: Bool
    @State private var passages: [ScripturePassageSelection] = [ScripturePassageSelection(bookIndex: 0, chapter: 1, verse: 1, verseEnd: 1)]
    @State private var notes: String = ""
    @State private var speaker: String = ""
    @State private var isPickerPresented: Bool = false
    @State private var pickerIndex: Int = 0
    @State private var showLeaveAlert = false
    @State private var passageToDelete: Int? = nil
    @State private var tempPickerSelection: ScripturePassageSelection = ScripturePassageSelection(bookIndex: 0, chapter: 1, verse: 1, verseEnd: 1)
    let date: Date

    init(entryToEdit: JournalEntry? = nil) {
        self.entryToEdit = entryToEdit
        var initialPassages: [ScripturePassageSelection]
        if let entryToEdit, let stored = entryToEdit.scripture, !stored.isEmpty {
            initialPassages = stored.components(separatedBy: ";").compactMap { ref in
                let regex = #"^([1-3]?\s?[A-Za-z ]+)\s+(\d+):(\d+)(?:-(\d+))?$"#
                guard let match = ref.range(of: regex, options: .regularExpression) else { return nil }
                let comps = String(ref[match]).components(separatedBy: .whitespaces)
                let book = comps.dropLast().joined(separator: " ")
                let last = comps.last ?? ""
                let chapterVerse = last.components(separatedBy: ":")
                guard let chapter = Int(chapterVerse[0]) else { return nil }
                let verseRange = chapterVerse.count > 1 ? chapterVerse[1].split(separator: "-").compactMap { Int($0) } : []
                let verse = verseRange.first ?? 1
                let verseEnd = verseRange.count > 1 ? verseRange.last! : verse
                let bookIndex = bibleBooks.firstIndex(where: { $0.name == book }) ?? 0
                return ScripturePassageSelection(bookIndex: bookIndex, chapter: chapter, verse: verse, verseEnd: verseEnd)
            }
        } else {
            initialPassages = [ScripturePassageSelection(bookIndex: 0, chapter: 1, verse: 1, verseEnd: 1)]
        }
        _passages = State(initialValue: initialPassages)
        _notes = State(initialValue: entryToEdit?.notes ?? "")
        _speaker = State(initialValue: entryToEdit?.speaker ?? "")
        _title = State(initialValue: entryToEdit?.title ?? "")
        self.date = entryToEdit?.date ?? Date()
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                titleSection
                passageList
                speakerSection
                divider
                notesSection
            }
            .background(Color.appWhite)
            .navigationTitle("Add Sermon Notes")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    if hasUnsavedChanges {
                        showLeaveAlert = true
                    } else {
                        dismiss()
                    }
                },
                trailing: Button(entryToEdit == nil ? "Add" : "Save") {
                    let passagesString = passages.map { $0.displayString(bibleBooks: bibleBooks) }
                        .filter { !$0.isEmpty }
                        .joined(separator: "; ")
                    if let entryToEdit = entryToEdit {
                        entryToEdit.title = title
                        entryToEdit.scripture = passagesString
                        entryToEdit.notes = notes
                        entryToEdit.speaker = speaker
                        try? modelContext.save()
                    } else {
                        let newEntry = JournalEntry(
                            section: JournalSection.sermonNotes.rawValue,
                            title: title,
                            date: date,
                            scripture: passagesString,
                            notes: notes,
                            speaker: speaker
                        )
                        modelContext.insert(newEntry)
                    }
                    dismiss()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          passages.allSatisfy { $0.displayString(bibleBooks: bibleBooks).isEmpty })
            )
            .alert("Unsaved Changes", isPresented: $showLeaveAlert) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You have unsaved changes. Are you sure you want to leave without saving?")
            }
            .alert("Delete Passage?", isPresented: Binding(
                get: { passageToDelete != nil },
                set: { if !$0 { passageToDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let idx = passageToDelete {
                        passages.remove(at: idx)
                        if pickerIndex >= passages.count { pickerIndex = passages.count - 1 }
                    }
                    passageToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    passageToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete this scripture passage?")
            }
            .sheet(isPresented: $isPickerPresented, onDismiss: {
                passages[pickerIndex] = tempPickerSelection
            }) {
                ScripturePickerView(
                    bibleBooks: bibleBooks,
                    selectedBookIndex: $tempPickerSelection.bookIndex,
                    selectedChapter: $tempPickerSelection.chapter,
                    selectedVerse: $tempPickerSelection.verse,
                    selectedVerseEnd: $tempPickerSelection.verseEnd
                )
                .presentationDetents([.fraction(0.35)])
            }
            .tint(Color.appGreenDark)
            .onAppear {
                if entryToEdit == nil {
                    isTitleFocused = true
                }
            }
        }
        .tint(Color.appGreenDark)
    }

    private var passageList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(formattedDate(date))
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 8)

            ForEach(passages.indices, id: \.self) { idx in
                passageRow(for: idx)
                    .padding(.bottom, 8)
            }
        }
        .padding(.horizontal)
    }

    private func passageRow(for idx: Int) -> some View {
        let binding = Binding<ScripturePassageSelection>(
            get: { passages[safe: idx] ?? ScripturePassageSelection(bookIndex: 0, chapter: 1, verse: 1, verseEnd: 1) },
            set: { passages[safe: idx] = $0 }
        )
        return PassageRow(
            passage: binding,
            isLast: idx == passages.count - 1,
            onAdd: {
                passages.append(ScripturePassageSelection(bookIndex: 0, chapter: 1, verse: 1, verseEnd: 1))
                pickerIndex = passages.count - 1
                tempPickerSelection = passages.last ?? ScripturePassageSelection(bookIndex: 0, chapter: 1, verse: 1, verseEnd: 1)
                isPickerPresented = true
            },
            onDelete: {
                passageToDelete = idx
            },
            isPickerPresented: Binding(
                get: { isPickerPresented && pickerIndex == idx },
                set: { newValue in
                    isPickerPresented = newValue
                    if newValue {
                        pickerIndex = idx
                        tempPickerSelection = passages[safe: idx] ?? ScripturePassageSelection(bookIndex: 0, chapter: 1, verse: 1, verseEnd: 1)
                    }
                }
            ),
            bibleBooks: bibleBooks,
            canDelete: passages.count > 1
        )
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Title", text: $title)
                .font(.title2)
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 8)
                .background(Color.appWhite)
                .cornerRadius(8)
                .focused($isTitleFocused)
        }
    }

    private var speakerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Speaker", text: $speaker)
                .font(.headline)
                .background(Color.appWhite)
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
    }

    private var divider: some View {
        Divider()
            .background(Color.appGreenDark)
            .padding(.vertical, 8)
            .padding(.horizontal)
    }

    private var notesSection: some View {
        ZStack {
            Color.appWhite
            TextEditor(text: $notes)
                .font(.body)
                .padding(4)
                .scrollContentBackground(.hidden)
                .onTapGesture {
                    isPickerPresented = false
                }
        }
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.bottom, 12)
        .frame(maxHeight: .infinity)
    }

    private var hasUnsavedChanges: Bool {
        // Implement your own logic to compare current state to original entry
        true // For demo purposes, always true
    }
}

struct AddSermonNotesView_Previews: PreviewProvider {
    static var previews: some View {
        AddSermonNotesView()
            .modelContainer(for: JournalEntry.self, inMemory: true)
    }
}
