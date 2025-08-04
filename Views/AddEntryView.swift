// AddEntryView.swift

import SwiftUI
import SwiftData

struct AddEntryView: View {
    @Environment(\.modelContext) private var modelContext
    var entryToEdit: JournalEntry? = nil
    let section: JournalSection
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var tagStore: TagStore

    @State private var title: String = ""
    @FocusState private var isTitleFocused: Bool
    @State private var notes: String = ""
    @State private var showLeaveAlert = false
    let date: Date
    @State private var showTagPicker = false
    @State private var selectedTagIDs: Set<UUID> = []

    private var currentSection: JournalSection {
        if let entryToEdit = entryToEdit {
            return JournalSection(rawValue: entryToEdit.section) ?? .other
        }
        return section
    }

    private var navigationTitle: String {
        entryToEdit == nil ? "Add \(currentSection.displayName) Entry" : "Edit \(currentSection.displayName) Entry"
    }

    // FIXED: Remove tagStore parameter since we're using @EnvironmentObject
    init(entryToEdit: JournalEntry? = nil, section: JournalSection = .other) {
        self.entryToEdit = entryToEdit
        self.section = section
        _notes = State(initialValue: entryToEdit?.notes ?? "")
        _title = State(initialValue: entryToEdit?.title ?? "")
        _selectedTagIDs = State(initialValue: Set(entryToEdit?.tagIDs ?? []))
        self.date = entryToEdit?.date ?? Date()
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                titleSection
                tagsSection
                divider
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
                        // Editing existing entry
                        entryToEdit.title = title
                        entryToEdit.notes = notes
                        entryToEdit.tagIDs = Array(selectedTagIDs)
                        try? modelContext.save()
                    } else {
                        // Creating new entry
                        let newEntry = JournalEntry(
                            section: currentSection.rawValue,
                            title: title,
                            date: date,
                            scripture: "",
                            notes: notes
                        )
                        newEntry.tagIDs = Array(selectedTagIDs)
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
            // FIXED: Remove tagStore parameter since TagPickerOverlay now uses @EnvironmentObject
            .overlay(
                TagPickerOverlay(
                    isPresented: $showTagPicker,
                    selectedTagIDs: $selectedTagIDs
                )
                .opacity(showTagPicker ? 1: 0)
                .animation(.easeInOut(duration: 0.2), value: showTagPicker)
            )
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
            HStack {
                TextField("Title", text: $title)
                    .font(.title2)
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                    .background(Color.appWhite)
                    .cornerRadius(8)
                    .focused($isTitleFocused)
                
                Text(formattedDate(date))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
            }
        }
    }
    
    private var tagsSection: some View {
        Button(action: { showTagPicker = true }) {
            HStack {
                if selectedTagIDs.isEmpty {
                    Text("Add Tags")
                        .foregroundColor(.secondary)
                } else {
                    Text("Tags Added")
                        .foregroundColor(.appGreenDark)
                        .fontWeight(.semibold)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundColor(.appGreenDark)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedTagIDs.isEmpty ? Color.appGreenPale : Color.appGreenLight)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .padding(.bottom, 8)
        .frame(width: UIScreen.main.bounds.width / 2)
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
        }
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.bottom, 12)
        .frame(maxHeight: .infinity)
    }

    private var hasUnsavedChanges: Bool {
        let originalTitle = entryToEdit?.title ?? ""
        let originalNotes = entryToEdit?.notes ?? ""
        let originalTagIDs = Set(entryToEdit?.tagIDs ?? [])
        
        return title != originalTitle ||
               notes != originalNotes ||
               selectedTagIDs != originalTagIDs
    }
    
    // Helper function for date formatting
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct AddEntryView_Previews: PreviewProvider {
    static var previews: some View {
         // New entry preview
            AddEntryView(section: .other)
                .environmentObject(TagStore())
                .modelContainer(for: JournalEntry.self, inMemory: true)
                .previewDisplayName("New Entry")
           
    }
}
