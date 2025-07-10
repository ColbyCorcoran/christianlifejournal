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
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(formattedDate(date))
                        .font(.headline.bold())
                        .foregroundColor(.appGreenDark)
                        .padding(.top, 24)
                        .padding(.bottom, 8)

                    ScripturePassagesInput(
                        scripturePassages: $scripturePassages,
                        focusedPassageIndex: $focusedPassageIndex
                    )

                    Divider()
                        .background(Color.appGreenDark)
                        .padding(.vertical, 8)
                }
                .padding(.horizontal)

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
                    let passagesString = passages.joined(separator: "; ")
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
                .disabled(scripturePassages.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            )
        }
        .tint(Color.appGreenDark)
    }
}

// MARK: - Helper View for Scripture Passages Input

struct ScripturePassagesInput: View {
    @Binding var scripturePassages: [String]
    @FocusState.Binding var focusedPassageIndex: Int?

    var body: some View {
        ForEach(scripturePassages.indices, id: \.self) { idx in
            HStack(alignment: .center, spacing: 8) {
                TextField("Scripture Passage", text: $scripturePassages[idx])
                    .font(.headline)
                    .background(Color.appWhite)
                    .cornerRadius(8)
                    .focused($focusedPassageIndex, equals: idx)
                    .onChange(of: scripturePassages[idx]) {
                        let newValue = scripturePassages[idx]
                        if idx < scripturePassages.count - 1 && newValue.isEmpty {
                            scripturePassages.remove(at: idx)
                        }
                    }
                if idx == scripturePassages.count - 1 &&
                    !scripturePassages[idx].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                    focusedPassageIndex == idx {
                    Button(action: {
                        scripturePassages.append("")
                        focusedPassageIndex = scripturePassages.count - 1
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.appGreenDark)
                            .font(.title2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.scale)
                }
            }
            .padding(.bottom, 8)
        }
    }
}


struct AddPersonalTimeView_Previews: PreviewProvider {
    static var previews: some View {
        AddPersonalTimeView()
            .modelContainer(for: JournalEntry.self, inMemory: true)
    }
}
