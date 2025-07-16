// AddEntryView.swift

// AddEntryView.swift

import SwiftUI
import SwiftData

struct AddEntryView: View {
    @Environment(\.modelContext) private var modelContext
    var entryToEdit: JournalEntry? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var passages: [ScripturePassageSelection] = [ScripturePassageSelection(bookIndex: 0, chapter: 1, verse: 1, verseEnd: 1)]
    @State private var notes: String = ""
    @State private var isPickerPresented: Bool = false
    @State private var pickerIndex: Int = 0
    @State private var showLeaveAlert = false
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
        self.date = entryToEdit?.date ?? Date()
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                passageList
                notesSection
            }
            .background(Color.appWhite)
            .navigationTitle(entryToEdit == nil ? "Add Entry" : "Edit Entry")
            .navigationBarItems(
                leading: Button("Cancel") {
                    if hasUnsavedChanges {
                        showLeaveAlert = true
                    } else {
                        dismiss()
                    }
                },
                trailing: Button(entryToEdit == nil ? "Add" : "Save") {
                    let passagesString = passages.map { $0.displayString(bibleBooks: bibleBooks) ?? "" }
                        .filter { !$0.isEmpty }
                        .joined(separator: "; ")
                    if let entryToEdit = entryToEdit {
                        entryToEdit.title = ""
                        entryToEdit.scripture = passagesString
                        entryToEdit.notes = notes
                        try? modelContext.save()
                    } else {
                        let newEntry = JournalEntry(
                            section: entryToEdit?.section ?? "",
                            title: "",
                            date: date,
                            scripture: passagesString,
                            notes: notes
                        )
                        modelContext.insert(newEntry)
                    }
                    dismiss()
                }
                .disabled(passages.allSatisfy { $0.displayString(bibleBooks: bibleBooks)?.isEmpty ?? true })
            )
            .alert("Unsaved Changes", isPresented: $showLeaveAlert) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You have unsaved changes. Are you sure you want to leave without saving?")
            }
            .sheet(isPresented: $isPickerPresented) {
                ScripturePickerView(
                    bibleBooks: bibleBooks,
                    selectedBookIndex: $passages[pickerIndex].bookIndex,
                    selectedChapter: $passages[pickerIndex].chapter,
                    selectedVerse: $passages[pickerIndex].verse,
                    selectedVerseEnd: $passages[pickerIndex].verseEnd
                )
                .presentationDetents([.fraction(0.35)])
            }
        }
        .tint(Color.appGreenDark)
    }

    private var passageList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(formattedDate(date))
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 24)
                .padding(.bottom, 8)

            ForEach(passages.indices, id: \.self) { idx in
                PassageRow(
                    passage: $passages[idx],
                    isLast: idx == passages.count - 1,
                    onAdd: {
                        passages.append(ScripturePassageSelection(bookIndex: 0, chapter: 1, verse: 1, verseEnd: 1))
                        pickerIndex = passages.count - 1
                        isPickerPresented = true
                    },
                    isPickerPresented: Binding(
                        get: { isPickerPresented && pickerIndex == idx },
                        set: { newValue in
                            isPickerPresented = newValue
                            if newValue { pickerIndex = idx }
                        }
                    ),
                    bibleBooks: bibleBooks
                )
                .padding(.bottom, 8)
            }

            Divider()
                .background(Color.appGreenDark)
                .padding(.vertical, 8)
        }
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

struct AddEntryView_Previews: PreviewProvider {
    static var previews: some View {
        AddEntryView()
            .modelContainer(for: JournalEntry.self, inMemory: true)
    }
}
