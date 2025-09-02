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
    let section: JournalSection // Add section parameter
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var speakerStore: SpeakerStore
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var binderStore: BinderStore
    
    @State private var title: String = ""
    @FocusState private var isTitleFocused: Bool
    @State private var selectedPassages: [ScripturePassageSelection] = []
    
    @State private var notes: String = ""
    @State private var selectedSpeaker: String = ""
    @State private var showScripturePicker = false
    @State private var showSpeakerPicker = false
    @State private var showLeaveAlert = false
    @State private var showTagPicker = false
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var showBinderPicker = false
    @State private var selectedBinderIDs: Set<UUID> = []
    
    // Remove isNewEntry since we're not using the old pattern anymore
    
    let date: Date
    
    private var currentSection: JournalSection {
        if let entryToEdit = entryToEdit {
            return JournalSection(rawValue: entryToEdit.section) ?? .sermonNotes
        }
        return section // Use the passed-in section for new entries
    }
    
    private var navigationTitle: String {
        entryToEdit == nil ? "Add \(currentSection.navigationTitle) Entry" : "Edit \(currentSection.navigationTitle) Entry"
    }
    
    // Updated init to include section parameter with default and preselected binder
    init(entryToEdit: JournalEntry? = nil, section: JournalSection = .sermonNotes, preselectedBinderID: UUID? = nil) {
        self.entryToEdit = entryToEdit
        self.section = section
        self.date = entryToEdit?.date ?? Date()
        
        // Initialize basic properties
        _notes = State(initialValue: entryToEdit?.notes ?? "")
        _title = State(initialValue: entryToEdit?.title ?? "")
        _selectedSpeaker = State(initialValue: entryToEdit?.speaker ?? "")
        _selectedTagIDs = State(initialValue: Set(entryToEdit?.tagIDs ?? []))
        _selectedBinderIDs = State(initialValue: preselectedBinderID != nil ? Set([preselectedBinderID!]) : Set())
        
        // Parse passages if they exist
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
                        // Sermon Details Card with Date in Upper Right
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Sermon Details")
                                    .font(.headline)
                                    .foregroundColor(.appGreenDark)
                                
                                Spacer()
                                
                                Text(formattedDate(date))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                            }
                            
                            // Title field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.appGreenDark)
                                
                                TextField("Enter sermon title...", text: $title)
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
                            }
                            
                            // Binder and Speaker section
                            HStack {
                                // Binder section
                                binderSection
                                
                                // Speaker section
                                speakerSection
                            }
                            
                            HStack {
                                // Scripture Passages section
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Scripture Passages")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.appGreenDark)
                                    
                                    Button(action: { showScripturePicker = true }) {
                                        HStack {
                                            if selectedPassages.isEmpty {
                                                Text("Select Verses")
                                                    .foregroundColor(.gray)
                                            } else {
                                                Text("\(selectedPassages.count) selected")
                                                    .foregroundColor(.appGreenDark)
                                                    .fontWeight(.medium)
                                            }
                                            Spacer()
                                            Image(systemName: "book")
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
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                // Tags section
                                tagsSection
                            }
                            
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                        
                        // Notes Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes & Reflections")
                                .font(.headline)
                                .foregroundColor(.appGreenDark)
                            
                            notesSection
                        }
                        .padding()
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
                        let passagesString = selectedPassages.compactMap { passage in
                            return passage.displayString(bibleBooks: bibleBooks)
                        }
                            .filter { !$0.isEmpty }
                            .joined(separator: "; ")
                        
                        // Add new speaker to SpeakerStore if it doesn't exist
                        if !selectedSpeaker.isEmpty && !speakerStore.speakers.contains(where: { $0.name == selectedSpeaker }) {
                            speakerStore.addSpeaker(selectedSpeaker)
                        }
                        
                        if let entryToEdit = entryToEdit {
                            // Editing existing entry
                            entryToEdit.title = title
                            entryToEdit.scripture = passagesString
                            entryToEdit.notes = notes
                            entryToEdit.speaker = selectedSpeaker
                            entryToEdit.tagIDs = Array(selectedTagIDs)
                            try? modelContext.save()
                            
                            // Update binder associations
                            binderStore.updateBinderAssociations(for: entryToEdit, selectedBinderIDs: selectedBinderIDs)
                        } else {
                            // Creating new entry - use the section parameter
                            let newEntry = JournalEntry(
                                section: currentSection.rawValue,
                                title: title,
                                date: date,
                                scripture: passagesString,
                                notes: notes,
                                speaker: selectedSpeaker
                            )
                            newEntry.tagIDs = Array(selectedTagIDs)
                            modelContext.insert(newEntry)
                            
                            // Add to selected binders
                            for binderID in selectedBinderIDs {
                                binderStore.addEntry(newEntry, to: binderID)
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
            .sheet(isPresented: $showTagPicker) {
                TagPickerSheet(selectedTagIDs: $selectedTagIDs)
                    .environmentObject(tagStore)
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
    
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.appGreenDark)
            
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
    
    private var notesSection: some View {
        ZStack(alignment: .topLeading) {
            if notes.isEmpty {
                Text("Record your thoughts, key takeaways, and insights...")
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
                .frame(minHeight: 225)
                .onTapGesture {
                    showScripturePicker = false
                }
        }
    }
    
    @ViewBuilder
    private var scripturePickerContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Add Passage Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add Scripture Passage")
                        .font(.headline)
                        .foregroundColor(.appGreenDark)
                    
                    Text("Select Scripture")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                
                // Selected passages
                if !selectedPassages.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Selected Passages")
                            .font(.headline)
                            .foregroundColor(.appGreenDark)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(selectedPassages.indices, id: \.self) { index in
                                HStack {
                                    Text("• \(selectedPassages[index].abbreviatedDisplayString(bibleBooks: bibleBooks) ?? "")")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        selectedPassages.remove(at: index)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.body)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.appGreenPale.opacity(0.3))
                                )
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                }
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(Color.appWhite.ignoresSafeArea())
    }
    
    private var hasUnsavedChanges: Bool {
        let originalTitle = entryToEdit?.title ?? ""
        let originalNotes = entryToEdit?.notes ?? ""
        let originalSpeaker = entryToEdit?.speaker ?? ""
        let originalTagIDs = Set(entryToEdit?.tagIDs ?? [])
        
        // Compare passages
        let originalPassagesString = entryToEdit?.scripture ?? ""
        let currentPassagesString = selectedPassages.compactMap { passage in
            return passage.displayString(bibleBooks: bibleBooks)
        }
            .filter { !$0.isEmpty }
            .joined(separator: "; ")
        
        return title != originalTitle ||
        notes != originalNotes ||
        selectedSpeaker != originalSpeaker ||
        selectedTagIDs != originalTagIDs ||
        currentPassagesString != originalPassagesString
    }
}

struct AddSermonNotesView_Previews: PreviewProvider {
    static var previews: some View {
        MockAddSermonNotesView()
    }
}

// MARK: - Mock Preview (SwiftData-Free)

class MockTagStore: ObservableObject {
    @Published var userTags: [Tag] = []
    func addTag(_ name: String) {}
    func removeTag(withId id: UUID) {}
    func updateTag(withId id: UUID, newName: String) {}
}

class MockSpeakerStore: ObservableObject {
    @Published var speakers: [Speaker] = []
    func addSpeaker(_ name: String) {}
    func removeSpeaker(withId id: UUID) {}
    func updateSpeaker(withId id: UUID, newName: String) {}
}

struct MockAddSermonNotesView: View {
    @StateObject private var mockTagStore = MockTagStore()
    @StateObject private var mockSpeakerStore = MockSpeakerStore()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appWhite.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Sermon Details Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Sermon Details")
                                    .font(.headline)
                                    .foregroundColor(.appGreenDark)
                                
                                Spacer()
                                
                                Text("August 14, 2025")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.appGreenDark)
                                
                                TextField("Enter sermon title...", text: .constant("Sample Sermon Title"))
                                    .textFieldStyle(.plain)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.appGreenDark, lineWidth: 1)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.appGreenPale.opacity(0.1))
                                            )
                                    )
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                        
                        // Notes Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes & Reflections")
                                .font(.headline)
                                .foregroundColor(.appGreenDark)
                            
                            Text("This is a preview of the sermon notes view...")
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.appGreenDark.opacity(0.3), lineWidth: 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.appGreenPale.opacity(0.1))
                                        )
                                )
                                .frame(minHeight: 150)
                        }
                        .padding()
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
            .navigationTitle("Add Sermon Notes Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {}
                        .foregroundColor(.appGreenDark)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {}
                        .foregroundColor(.appGreenDark)
                }
            }
        }
    }
}
