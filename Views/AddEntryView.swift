// AddEntryView.swift

// AddEntryView.swift

import SwiftUI
import SwiftData

struct AddEntryView: View {
    @Environment(\.modelContext) private var modelContext
    let section: JournalSection
    var entryToEdit: JournalEntry? = nil
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String
    @State private var bodyText: String
    let date: Date

    init(section: JournalSection, entryToEdit: JournalEntry? = nil) {
        self.section = section
        self.entryToEdit = entryToEdit
        _title = State(initialValue: entryToEdit?.title ?? "")
        _bodyText = State(initialValue: entryToEdit?.bodyText ?? "")
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
                        .background(Color.appGray)
                        .cornerRadius(8)
                        .padding(.top, 24)

                    Text(formattedDate(date))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)

                    ZStack {
                        Color.appGray
                        TextEditor(text: $bodyText)
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
            .background(Color.appGray)
            .navigationTitle(entryToEdit == nil ? "Add \(section.rawValue) Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(entryToEdit == nil ? "Add" : "Save") {
                    if let entryToEdit = entryToEdit {
                        entryToEdit.title = title
                        entryToEdit.bodyText = bodyText
                        try? modelContext.save()
                    } else {
                        let newEntry = JournalEntry(
                            section: section.rawValue,
                            title: title,
                            date: date,
                            bodyText: bodyText
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

struct AddEntryView_Previews: PreviewProvider {
    static var previews: some View {
        AddEntryView(section: .prayerJournal)
            .modelContainer(for: JournalEntry.self, inMemory: true)
    }
}
