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
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String
    @State private var speaker: String
    @State private var notes: String
    let date: Date

    init(entryToEdit: JournalEntry? = nil) {
        self.entryToEdit = entryToEdit
        _title = State(initialValue: entryToEdit?.title ?? "")
        _speaker = State(initialValue: entryToEdit?.speaker ?? "")
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

                    TextField("Speaker", text: $speaker)
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
            .navigationTitle(entryToEdit == nil ? "Add Sermon Notes Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(entryToEdit == nil ? "Add" : "Save") {
                    if let entryToEdit = entryToEdit {
                        entryToEdit.title = title
                        entryToEdit.speaker = speaker
                        entryToEdit.notes = notes
                        try? modelContext.save()
                    } else {
                        let newEntry = JournalEntry(
                            section: JournalSection.sermonNotes.rawValue,
                            title: title,
                            date: date,
                            notes: notes, speaker: speaker
                        )
                        modelContext.insert(newEntry)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            )
        }
        .tint(Color.appBlue)
    }
}

struct AddSermonNotesView_Previews: PreviewProvider {
    static var previews: some View {
        AddSermonNotesView()
            .modelContainer(for: JournalEntry.self, inMemory: true)
    }
}
