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
    @State private var scripturePassages: [String]
    @State private var notes: String
    @FocusState private var focusedPassageIndex: Int?
    let date: Date

    init(entryToEdit: JournalEntry? = nil) {
        self.entryToEdit = entryToEdit
        // If you already store as [String], use that; otherwise, split on ";"
        let passages: [String]
        if let entryToEdit, let stored = entryToEdit.scripture, !stored.isEmpty {
            passages = stored.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        } else {
            passages = [""]
        }
        _scripturePassages = State(initialValue: passages)
        _notes = State(initialValue: entryToEdit?.notes ?? "")
        self.date = entryToEdit?.date ?? Date()
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(formattedDate(date))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 24)
                        .padding(.bottom, 8)

                    // Scripture Passages
                    ForEach(scripturePassages.indices, id: \.self) { idx in
                        HStack(alignment: .center, spacing: 8) {
                            TextField("Scripture Passage", text: $scripturePassages[idx])
                                .font(.headline)
                                .background(Color.appWhite)
                                .cornerRadius(8)
                                .focused($focusedPassageIndex, equals: idx)
                                .onChange(of: scripturePassages[idx]) {
                                    let newValue = scripturePassages[idx]
                                    // Remove empty trailing fields except the last
                                    if idx < scripturePassages.count - 1 && newValue.isEmpty {
                                        scripturePassages.remove(at: idx)
                                    }
                                }
                            // Show "+" button only for the last, non-empty, focused field
                            if idx == scripturePassages.count - 1 &&
                                !scripturePassages[idx].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                                focusedPassageIndex == idx {
                                Button(action: {
                                    scripturePassages.append("")
                                    focusedPassageIndex = scripturePassages.count - 1
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.appBlue)
                                        .font(.title2)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .transition(.scale)
                            }
                        }
                        .padding(.bottom, 8)
                    }

                    ZStack {
                        Color.appWhite
                        TextEditor(text: $notes)
                            .font(.body)
                            .padding(4)
                            .scrollContentBackground(.hidden)
                    }
                    .cornerRadius(8)
                    .frame(maxHeight: .infinity)
                }
                .padding(.horizontal)
                Spacer()
            }
            .background(Color.appWhite)
            .navigationTitle(entryToEdit == nil ? "Add Personal Time" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(entryToEdit == nil ? "Add" : "Save") {
                    let passages = scripturePassages
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    let passagesString = passages.joined(separator: "; ") // For now, store as a single string
                    if let entryToEdit = entryToEdit {
                        entryToEdit.title = "" // Not used for Personal Time
                        entryToEdit.scripture = passagesString
                        entryToEdit.notes = notes
                        try? modelContext.save()
                    } else {
                        let newEntry = JournalEntry(
                            section: JournalSection.personalTime.rawValue,
                            title: "", // Not used for Personal Time
                            date: date,
                            scripture: passagesString,
                            notes: notes
                        )
                        modelContext.insert(newEntry)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(scripturePassages.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            )
        }
        .tint(Color.appBlue)
    }
}

struct AddPersonalTimeView_Previews: PreviewProvider {
    static var previews: some View {
        AddPersonalTimeView()
            .modelContainer(for: JournalEntry.self, inMemory: true)
    }
}
