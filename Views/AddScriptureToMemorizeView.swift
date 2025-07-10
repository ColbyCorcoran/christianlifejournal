//
//  AddScriptureToMemorizeView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import SwiftUI
import SwiftData

struct AddScriptureToMemorizeView: View {
    @Environment(\.modelContext) private var modelContext
    var entryToEdit: JournalEntry? = nil
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String
    @State private var scripture: String
    @State private var notes: String
    let date: Date

    init(entryToEdit: JournalEntry? = nil) {
        self.entryToEdit = entryToEdit
        _title = State(initialValue: entryToEdit?.title ?? "")
        _scripture = State(initialValue: entryToEdit?.scripture ?? "")
        _notes = State(initialValue: entryToEdit?.notes ?? "")
        self.date = entryToEdit?.date ?? Date()
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    TextField("Title", text: $title)
                        .font(.title)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .background(Color.appWhite)
                        .cornerRadius(8)
                        .padding(.top, 24)

                    Text(formattedDate(date))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)

                    TextField("Scripture Passage", text: $scripture)
                        .font(.headline)
                        .background(Color.appWhite)
                        .cornerRadius(8)
                        .padding(.bottom, 8)

                    ZStack {
                        Color.appWhite
                        TextEditor(text: $notes)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .textEditorStyle(.plain) // Removes default insets
                                .padding(0) // Remove any extra padding
                    }
                    .cornerRadius(8)
                    .frame(maxHeight: .infinity)
                }
                .padding(.horizontal)
                Spacer()
            }
            .background(Color.appWhite)
            .navigationTitle(entryToEdit == nil ? "Add Scripture to Memorize" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(entryToEdit == nil ? "Add" : "Save") {
                    if let entryToEdit = entryToEdit {
                        entryToEdit.title = title
                        entryToEdit.scripture = scripture
                        entryToEdit.notes = notes
                        try? modelContext.save()
                    } else {
                        let newEntry = JournalEntry(
                            section: JournalSection.scriptureToMemorize.rawValue,
                            title: title,
                            date: date,
                            scripture: scripture,
                            notes: notes
                        )
                        modelContext.insert(newEntry)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            )
        }
        .tint(Color.appGreenDark)
    }
}

struct AddScriptureToMemorizeView_Previews: PreviewProvider {
    static var previews: some View {
        AddScriptureToMemorizeView()
            .modelContainer(for: JournalEntry.self, inMemory: true)
    }
}
