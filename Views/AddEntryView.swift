// AddEntryView.swift

// AddEntryView.swift

import SwiftUI
import SwiftData

struct AddEntryView: View {
    @Environment(\.modelContext) private var modelContext
    var entryToEdit: JournalEntry? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @FocusState private var isTitleFocused: Bool
    @State private var notes: String = ""
    @State private var showLeaveAlert = false
    let date: Date

    private var section: JournalSection {
        if let entryToEdit = entryToEdit {
            return JournalSection(rawValue: entryToEdit.section) ?? .other
        }
        return .other
    }

    private var navigationTitle: String {
        "Add \(section.displayName) Entry"
    }

    init(entryToEdit: JournalEntry? = nil) {
        self.entryToEdit = entryToEdit
        _notes = State(initialValue: entryToEdit?.notes ?? "")
        _title = State(initialValue: entryToEdit?.title ?? "")
        self.date = entryToEdit?.date ?? Date()
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                titleSection
                notesSection
            }
            .background(Color.appWhite)
            .navigationTitle(navigationTitle)
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
                    if let entryToEdit = entryToEdit {
                        entryToEdit.title = title
                        entryToEdit.notes = notes
                        try? modelContext.save()
                    } else {
                        let newEntry = JournalEntry(
                            section: entryToEdit?.section ?? "",
                            title: title,
                            date: date,
                            scripture: "",
                            notes: notes
                        )
                        modelContext.insert(newEntry)
                    }
                    dismiss()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
            .alert("Unsaved Changes", isPresented: $showLeaveAlert) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You have unsaved changes. Are you sure you want to leave without saving?")
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

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(formattedDate(date))
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 8)

            Divider()
                .background(Color.appGreenDark)
                .padding(.vertical, 8)

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
        .padding(.horizontal)
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
