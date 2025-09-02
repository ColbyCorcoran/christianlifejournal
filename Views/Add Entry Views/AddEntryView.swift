// AddEntryView.swift

import SwiftUI
import SwiftData

struct AddEntryView: View {
    @Environment(\.modelContext) private var modelContext
    var entryToEdit: JournalEntry? = nil
    let section: JournalSection
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var speakerStore: SpeakerStore
    @EnvironmentObject var binderStore: BinderStore
    
    @State private var title: String = ""
    @FocusState private var isTitleFocused: Bool
    @State private var notes: String = ""
    @State private var showLeaveAlert = false
    let date: Date
    @State private var showTagPicker = false
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var showScripturePicker = false
    @State private var selectedPassages: [ScripturePassageSelection] = []
    @State private var showSpeakerPicker = false
    @State private var selectedSpeaker: String = ""
    @State private var showBinderPicker = false
    @State private var selectedBinderIDs: Set<UUID> = []
    
    private var currentSection: JournalSection {
        if let entryToEdit = entryToEdit {
            return JournalSection(rawValue: entryToEdit.section) ?? .other
        }
        return section
    }
    
    private var navigationTitle: String {
        entryToEdit == nil ? "Add \(currentSection.navigationTitle) Entry" : "Edit \(currentSection.navigationTitle) Entry"
    }
    
    // FIXED: Remove tagStore parameter since we're using @EnvironmentObject
    init(entryToEdit: JournalEntry? = nil, section: JournalSection = .other, preselectedBinderID: UUID? = nil) {
        self.entryToEdit = entryToEdit
        self.section = section
        _notes = State(initialValue: entryToEdit?.notes ?? "")
        _title = State(initialValue: entryToEdit?.title ?? "")
        _selectedTagIDs = State(initialValue: Set(entryToEdit?.tagIDs ?? []))
        _selectedSpeaker = State(initialValue: entryToEdit?.speaker ?? "")
        _selectedBinderIDs = State(initialValue: preselectedBinderID != nil ? Set([preselectedBinderID!]) : Set())
        self.date = entryToEdit?.date ?? Date()
        
        // Parse scripture passages if they exist
        var initialPassages: [ScripturePassageSelection] = []
        if let entryToEdit = entryToEdit,
           let stored = entryToEdit.scripture,
           !stored.isEmpty {
            let components = stored.components(separatedBy: ";")
            initialPassages = components.compactMap { ref in
                let trimmedRef = ref.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedRef.isEmpty else { return nil }
                return Self.parseScriptureReference(trimmedRef)
            }
        }
        _selectedPassages = State(initialValue: initialPassages)
    }
    
    private static func parseScriptureReference(_ ref: String) -> ScripturePassageSelection? {
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
        let bookIndex = bibleBooks.firstIndex(where: { $0.name == book }) ?? -1
        return ScripturePassageSelection(bookIndex: bookIndex, chapter: chapter, verse: verse, verseEnd: verseEnd)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appWhite.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Entry Details Card with Date in Upper Right
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Entry Details")
                                    .font(.headline)
                                    .foregroundColor(.appGreenDark)
                                
                                Spacer()
                                
                                Text(formattedDate(date))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                            }
                            
                            // Just the title field now
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.appGreenDark)
                                
                                TextField("Enter entry title...", text: $title)
                                    .textFieldStyle(.plain)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.appGreenDark, lineWidth: 1)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.appGreenPale.opacity(0.1))
                                            )
                                    )
                                    .focused($isTitleFocused)
                                
                                // Binder and Speaker section (conditional layout)
                                if currentSection == .sermonNotes || currentSection == .groupNotes {
                                    // For sermon notes and group notes: HStack with binders + speaker
                                    HStack {
                                        binderSection
                                        speakerSection
                                    }
                                } else {
                                    // For other entry types: full-width binders section
                                    binderSection
                                }
                        
                                HStack {
                                    // Scripture Passages Card
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Scripture Passages")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.appGreenDark)
                                        
                                        Button(action: { showScripturePicker = true }) {
                                            HStack {
                                                Text(selectedPassages.isEmpty ? "Select Verses" : "\(selectedPassages.count) selected")
                                                    .font(.body)
                                                    .foregroundColor(selectedPassages.isEmpty ? .gray : .appGreenDark)
                                                
                                                Spacer()
                                                
                                                Image(systemName: selectedPassages.isEmpty ? "book" : "book.fill")
                                                    .foregroundColor(.appGreenDark)
                                            }
                                            .padding(8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.appGreenDark, lineWidth: 1)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(selectedPassages.isEmpty ? Color.clear : Color.appGreenPale.opacity(0.3))
                                                    )
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    
                                    // Tags Card
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Tags")
                                            .font(.subheadline)
                                            .foregroundColor(.appGreenDark)
                                        
                                        tagsSection
                                    }
                                }
                                
                                
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                        
                        
                        // Notes Card (Taller)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes & Reflections")
                                .font(.headline)
                                .foregroundColor(.appGreenDark)
                            
                            notesSection
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            showLeaveAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(.appGreenDark)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(entryToEdit == nil ? "Add" : "Save") {
                        // Format scripture passages
                        let passagesString = selectedPassages.compactMap { passage in
                            return passage.displayString(bibleBooks: bibleBooks)
                        }
                            .filter { !$0.isEmpty }
                            .joined(separator: "; ")
                        
                        if let entryToEdit = entryToEdit {
                            // Editing existing entry
                            entryToEdit.title = title
                            entryToEdit.notes = notes
                            entryToEdit.scripture = passagesString.isEmpty ? nil : passagesString
                            entryToEdit.tagIDs = Array(selectedTagIDs)
                            entryToEdit.speaker = selectedSpeaker.isEmpty ? nil : selectedSpeaker
                            try? modelContext.save()
                            
                            // Update binder associations
                            binderStore.updateBinderAssociations(for: entryToEdit, selectedBinderIDs: selectedBinderIDs)
                        } else {
                            // Creating new entry
                            let newEntry = JournalEntry(
                                section: currentSection.rawValue,
                                title: title,
                                date: date,
                                scripture: passagesString.isEmpty ? nil : passagesString,
                                notes: notes,
                                speaker: selectedSpeaker.isEmpty ? nil : selectedSpeaker
                            )
                            newEntry.tagIDs = Array(selectedTagIDs)
                            modelContext.insert(newEntry)
                            
                            // Add to selected binders
                            for binderID in selectedBinderIDs {
                                binderStore.addEntry(newEntry, to: binderID)
                            }
                        }
                        
                        // Auto-add speaker to SpeakerStore if it doesn't exist and entry supports speakers
                        if (currentSection == .sermonNotes || currentSection == .groupNotes) && !selectedSpeaker.isEmpty {
                            if !speakerStore.speakers.contains(where: { $0.name == selectedSpeaker }) {
                                speakerStore.addSpeaker(selectedSpeaker)
                            }
                        }
                        
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(.appGreenDark)
                }
            }
            .alert("Unsaved Changes", isPresented: $showLeaveAlert) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You have unsaved changes. Are you sure you want to leave without saving?")
            }
            .sheet(isPresented: $showTagPicker) {
                TagPickerSheet(selectedTagIDs: $selectedTagIDs)
                    .environmentObject(tagStore)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showScripturePicker) {
                ScripturePickerSheet(selectedPassages: $selectedPassages)
                    .presentationDetents([.large, .medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showSpeakerPicker) {
                SpeakerPickerSheet(selectedSpeaker: $selectedSpeaker)
                    .environmentObject(speakerStore)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showBinderPicker) {
                BinderPickerSheet(selectedBinderIDs: $selectedBinderIDs)
                    .environmentObject(binderStore)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .tint(Color.appGreenDark)
            .onAppear {
                if entryToEdit == nil {
                    isTitleFocused = true
                } else if let entry = entryToEdit {
                    // Initialize binder selection for editing
                    let entryBinders = binderStore.bindersContaining(journalEntryID: entry.id)
                    selectedBinderIDs = Set(entryBinders.map { $0.id })
                }
            }
        }
        .tint(Color.appGreenDark)
    }
    
    
    private var tagsSection: some View {
        Button(action: { showTagPicker = true }) {
            HStack {
                Text(selectedTagIDs.isEmpty ? "Select Tags" : "\(selectedTagIDs.count) selected")
                    .font(.body)
                    .foregroundColor(selectedTagIDs.isEmpty ? .gray : .appGreenDark)
                
                Spacer()
                
                Image(systemName: selectedTagIDs.isEmpty ? "tag" : "tag.fill")
                    .foregroundColor(.appGreenDark)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.appGreenDark, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTagIDs.isEmpty ? Color.clear : Color.appGreenPale.opacity(0.3))
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var binderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Binders")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.appGreenDark)
            
            Button(action: { showBinderPicker = true }) {
                HStack {
                    Text(selectedBinderIDs.isEmpty ? "Select Binders" : "\(selectedBinderIDs.count) selected")
                        .font(.body)
                        .foregroundColor(selectedBinderIDs.isEmpty ? .gray : .appGreenDark)
                    
                    Spacer()
                    
                    Image(systemName: selectedBinderIDs.isEmpty ? "books.vertical" : "books.vertical.fill")
                        .foregroundColor(.appGreenDark)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appGreenDark, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedBinderIDs.isEmpty ? Color.clear : Color.appGreenPale.opacity(0.3))
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var speakerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Speaker")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.appGreenDark)
            
            Button(action: { showSpeakerPicker = true }) {
                HStack {
                    Text(selectedSpeaker.isEmpty ? "Select Speaker" : selectedSpeaker)
                            .foregroundColor(selectedSpeaker.isEmpty ? .gray : .appGreenDark)
                    
                    Spacer()
                    
                    Image(systemName: selectedSpeaker.isEmpty ? "person" : "person.fill")
                        .foregroundColor(.appGreenDark)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appGreenDark, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedSpeaker.isEmpty ? Color.clear : Color.appGreenPale.opacity(0.3))
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var notesSection: some View {
        ZStack(alignment: .topLeading) {
            if notes.isEmpty {
                Text("Record your thoughts, reflections, and insights...")
                    .foregroundColor(.gray)
                    .italic()
                    .padding(.bottom, 4)
                    .padding(.top, 8)
                    .padding(.leading, 5)
            }
            
            TextEditor(text: $notes)
                .font(.body)
                .scrollContentBackground(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appGreenDark.opacity(0.3), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.appGreenPale.opacity(0.1))
                        )
                )
                .frame(minHeight: 375)
        }
    }
    
    private var hasUnsavedChanges: Bool {
        let originalTitle = entryToEdit?.title ?? ""
        let originalNotes = entryToEdit?.notes ?? ""
        let originalTagIDs = Set(entryToEdit?.tagIDs ?? [])
        let originalSpeaker = entryToEdit?.speaker ?? ""
        
        // Compare passages
        let originalPassagesString = entryToEdit?.scripture ?? ""
        let currentPassagesString = selectedPassages.compactMap { passage in
            return passage.displayString(bibleBooks: bibleBooks)
        }
            .filter { !$0.isEmpty }
            .joined(separator: "; ")
        
        return title != originalTitle ||
        notes != originalNotes ||
        selectedTagIDs != originalTagIDs ||
        selectedSpeaker != originalSpeaker ||
        currentPassagesString != originalPassagesString
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
            .environmentObject(previewTagStore)
            .environmentObject(previewSpeakerStore)
            .modelContainer(previewContainer)
            .previewDisplayName("New Entry")
        
        // Group Notes preview (with speaker)
        AddEntryView(section: .groupNotes)
            .environmentObject(previewTagStore)
            .environmentObject(previewSpeakerStore)
            .modelContainer(previewContainer)
            .previewDisplayName("Group Notes")
    }
}
