//
//  AddPersonalTimeView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import SwiftUI
import SwiftData

struct AddPersonalTimeView: View {
    @Environment(\.modelContext) private var modelContext
    var entryToEdit: JournalEntry? = nil
    @Environment(\.presentationMode) var presentationMode

    @State private var passages: [String]
    @State private var references: [ScriptureReference?]
    @State private var notes: String
    let date: Date

    init(entryToEdit: JournalEntry? = nil) {
        self.entryToEdit = entryToEdit
        let storedPassages: [String]
        if let entryToEdit, let stored = entryToEdit.scripture, !stored.isEmpty {
            storedPassages = stored.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        } else {
            storedPassages = [""]
        }
        _passages = State(initialValue: storedPassages)
        _notes = State(initialValue: entryToEdit?.notes ?? "")
        self.date = entryToEdit?.date ?? Date()
        _references = State(initialValue: storedPassages.map { parseScriptureReference($0, bibleBooks: bibleBooks) })
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                passageList
                notesSection
                reflectionBox
            }
            .background(Color.appWhite)
            .navigationTitle(entryToEdit == nil ? "Add Personal Time Entry" : "Edit Entry")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(entryToEdit == nil ? "Add" : "Save") {
                    let validPassages = passages
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    let passagesString = validPassages.joined(separator: "; ")
                    if let entryToEdit = entryToEdit {
                        entryToEdit.title = ""
                        entryToEdit.scripture = passagesString
                        entryToEdit.notes = notes
                        try? modelContext.save()
                    } else {
                        let newEntry = JournalEntry(
                            section: JournalSection.personalTime.rawValue,
                            title: "",
                            date: date,
                            scripture: passagesString,
                            notes: notes
                        )
                        modelContext.insert(newEntry)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(passages.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                          || references.contains(where: { $0?.isValid == false }))
            )
        }
        .tint(Color.appGreenDark)
    }

    // MARK: - Computed Properties

    private var passageList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(formattedDate(date))
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 24)
                .padding(.bottom, 8)

            ForEach(passages.indices, id: \.self) { idx in
                PassageRow(
                    text: $passages[idx],
                    reference: $references[idx],
                    isLast: idx == passages.count - 1,
                    onAdd: {
                        passages.append("")
                        references.append(nil)
                    }
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
        }
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.bottom, 12)
        .frame(maxHeight: .infinity)
    }

    private var reflectionBox: some View {
        VStack(alignment: .center, spacing: 12) {
                            Text("What do these Scriptures say about God?")
                                .font(.body.bold())
                                .foregroundColor(.appWhite)
                            Text("What do these Scriptures say about man?")
                                .font(.body.bold())
                                .foregroundColor(.appWhite)
                            Text("How is God asking me to obey?")
                                .font(.body.bold())
                                .foregroundColor(.appWhite)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.appGreenDark)
                                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 16)
    }
}

// MARK: - Helper Row View for Each Passage

struct PassageRow: View {
    @Binding var text: String
    @Binding var reference: ScriptureReference?
    var isLast: Bool
    var onAdd: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            ScripturePassageField(
                text: $text,
                reference: $reference,
                bibleBooks: bibleBooks
            )
            if isLast && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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

struct AddPersonalTimeView_Previews: PreviewProvider {
    static var previews: some View {
        AddPersonalTimeView()
            .modelContainer(for: JournalEntry.self, inMemory: true)
    }
}
