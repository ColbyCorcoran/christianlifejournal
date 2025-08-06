//
//  AddScriptureMemoryView.swift
//  Christian Life Journal
//
//  Created by Scripture Memorization System Implementation
//

import SwiftUI
import SwiftData

enum AddMemoryMode {
    case startNew
    case addExisting
}

struct AddScriptureMemoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var memorizationSettings: MemorizationSettings
    @EnvironmentObject var tagStore: TagStore
    
    // Entry to edit (nil for new entries)
    let entryToEdit: ScriptureMemoryEntry?
    
    // MARK: - State Variables
    @State private var selectedMode: AddMemoryMode? = nil
    @State private var passageText: String = ""
    @State private var showScripturePicker = false
    
    // Scripture passage selection (works with existing overlay)
    @State private var scripturePassage: ScripturePassageSelection = ScripturePassageSelection(bookIndex: -1, chapter: 1, verse: 1, verseEnd: 1)
    
    // Add Existing Entry state
    @State private var selectedPhase: MemorizationPhase = .phase1
    @State private var completedCount: Int = 0
    @State private var hasCompletedToday: Bool = false
    @State private var showPhaseQuestions = false
    
    // Computed property for bible reference string
    private var bibleReference: String {
        return scripturePassage.displayString(bibleBooks: bibleBooks) ?? ""
    }
    
    // Validation
    private var isValidEntry: Bool {
        !bibleReference.trimmingCharacters(in: .whitespaces).isEmpty &&
        !passageText.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // MARK: - Initializer
    init(entryToEdit: ScriptureMemoryEntry? = nil) {
        self.entryToEdit = entryToEdit
        
        // Pre-populate fields if editing
        if let entry = entryToEdit {
            _passageText = State(initialValue: entry.passageText)
            // Parse the bible reference back to a passage selection
            _scripturePassage = State(initialValue: parseReferenceToPassage(entry.bibleReference))
        }
    }
    
    // Helper function to parse string reference back to passage selection
    private func parseReferenceToPassage(_ reference: String) -> ScripturePassageSelection {
        // Simple parsing - you might want to make this more robust
        let parts = reference.components(separatedBy: " ")
        guard parts.count >= 2 else {
            return ScripturePassageSelection(bookIndex: -1, chapter: 1, verse: 1, verseEnd: 1)
        }
        
        let bookName = parts[0]
        let chapterVerse = parts[1]
        
        // Find book index
        guard let bookIndex = bibleBooks.firstIndex(where: { $0.name == bookName }) else {
            return ScripturePassageSelection(bookIndex: -1, chapter: 1, verse: 1, verseEnd: 1)
        }
        
        // Parse chapter:verse
        let chapterVerseParts = chapterVerse.components(separatedBy: ":")
        guard chapterVerseParts.count == 2,
              let chapter = Int(chapterVerseParts[0]) else {
            return ScripturePassageSelection(bookIndex: bookIndex, chapter: 1, verse: 1, verseEnd: 1)
        }
        
        // Parse verse range
        let versePart = chapterVerseParts[1]
        let verseRange = versePart.components(separatedBy: "-")
        guard let startVerse = Int(verseRange[0]) else {
            return ScripturePassageSelection(bookIndex: bookIndex, chapter: chapter, verse: 1, verseEnd: 1)
        }
        
        let endVerse: Int
        if verseRange.count > 1, let end = Int(verseRange[1]) {
            endVerse = end
        } else {
            endVerse = startVerse
        }
        
        return ScripturePassageSelection(
            bookIndex: bookIndex,
            chapter: chapter,
            verse: startVerse,
            verseEnd: endVerse
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appWhite.ignoresSafeArea()
                
                if entryToEdit != nil {
                    // Editing existing entry
                    editEntryView
                } else if memorizationSettings.isSystemEnabled {
                    // System ON: Show mode selection or entry form
                    systemOnView
                } else {
                    // System OFF: Simple entry form
                    systemOffView
                }
                
                // Scripture Picker Overlay (using existing framework)
                if showScripturePicker {
                    ScripturePickerOverlay(
                        bibleBooks: bibleBooks,
                        isPresented: $showScripturePicker,
                        passages: $scripturePassage
                    )
                    .zIndex(2)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button(saveButtonTitle) {
                    saveEntry()
                }
                .disabled(!isValidEntry)
            )
        }
        .tint(.appGreenDark)
    }
    
    // MARK: - View Components
    
    private var navigationTitle: String {
        if entryToEdit != nil {
            return "Edit Scripture"
        } else if memorizationSettings.isSystemEnabled {
            return "Add Memory Verse"
        } else {
            return "Add Scripture Card"
        }
    }
    
    private var saveButtonTitle: String {
        entryToEdit != nil ? "Save" : "Add"
    }
    
    @ViewBuilder
    private var systemOnView: some View {
        if selectedMode == nil {
            // Mode selection screen
            modeSelectionView
        } else {
            // Entry form
            entryFormView
        }
    }
    
    private var systemOffView: some View {
        VStack {
            Text("Create a new scripture flashcard")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            
            entryFormView
        }
    }
    
    private var editEntryView: some View {
        VStack {
            Text("Edit your scripture memory entry")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            
            entryFormView
        }
    }
    
    private var modeSelectionView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Image(systemName: "book.closed")
                    .font(.system(size: 48))
                    .foregroundColor(.appGreenDark)
                
                Text("Add Memory Verse")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Choose how you'd like to add this verse to your memorization system")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            VStack(spacing: 16) {
                Button(action: {
                    selectedMode = .startNew
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.appGreenDark)
                                Text("Start New Memory Verse")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            Text("Begin with Day 1 of Phase 1 (25 repetitions)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appGreenPale)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    selectedMode = .addExisting
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.appGreenDark)
                                Text("Add Existing Memory Verse")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            Text("Already working on this verse? Set your current progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appGreenLight)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    private var entryFormView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Bible Reference Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bible Reference")
                        .font(.headline)
                        .foregroundColor(.appGreenDark)
                    
                    Button(action: {
                        showScripturePicker = true
                    }) {
                        HStack {
                            Text(bibleReference.isEmpty ? "Select Bible Reference" : bibleReference)
                                .foregroundColor(bibleReference.isEmpty ? .gray : .primary)
                            Spacer()
                            Image(systemName: "book.closed")
                                .foregroundColor(.appGreenDark)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.appGreenDark, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Passage Text Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Passage Text")
                        .font(.headline)
                        .foregroundColor(.appGreenDark)
                    
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appGreenDark, lineWidth: 1)
                            .frame(minHeight: 120)
                        
                        TextEditor(text: $passageText)
                            .padding(8)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                    }
                }
                
                // Phase Questions (for Add Existing mode)
                if selectedMode == .addExisting && memorizationSettings.isSystemEnabled {
                    phaseQuestionsView
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var phaseQuestionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
            
            Text("Current Progress")
                .font(.headline)
                .foregroundColor(.appGreenDark)
            
            Text("Which phase are you currently in for this passage?")
                .font(.subheadline)
                
            
            // Phase Selection
            Picker("Phase", selection: $selectedPhase) {
                ForEach(MemorizationPhase.allCases, id: \.self) { phase in
                    Text(phase.rawValue).tag(phase)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 8)
            
            // Completion Count Question
            VStack(alignment: .leading, spacing: 8) {
                Text(completionCountQuestion)
                    .font(.subheadline)
                
                HStack {
                    TextField("0", value: $completedCount, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                        .keyboardType(.numberPad)
                    
                    Text(completionCountUnit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            // Today's Completion Question
            Toggle(isOn: $hasCompletedToday) {
                Text(todayCompletionQuestion)
                    .font(.subheadline)
            }
            .tint(.appGreenDark)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appGreenPale.opacity(0.3))
        )
    }
    
    // MARK: - Helper Properties
    
    private var completionCountQuestion: String {
        switch selectedPhase {
        case .phase1:
            return "How many days of Phase 1 have you completed?"
        case .phase2:
            return "How many days of Phase 2 have you completed?"
        case .phase3:
            return "How many months of Phase 3 have you completed?"
        }
    }
    
    private var completionCountUnit: String {
        switch selectedPhase {
        case .phase1, .phase2:
            return "days"
        case .phase3:
            return "months"
        }
    }
    
    private var todayCompletionQuestion: String {
        switch selectedPhase {
        case .phase1, .phase2:
            return "Have you completed today's review?"
        case .phase3:
            return "Have you completed this month's review?"
        }
    }
    
    // MARK: - Save Entry
    
    private func saveEntry() {
        let trimmedReference = bibleReference.trimmingCharacters(in: .whitespaces)
        let trimmedPassage = passageText.trimmingCharacters(in: .whitespaces)
        
        if let existingEntry = entryToEdit {
            // Update existing entry
            existingEntry.bibleReference = trimmedReference
            existingEntry.passageText = trimmedPassage
            // Auto-tag with Bible book
            updateAutoTags(for: existingEntry)
        } else {
            // Create new entry
            let newEntry = ScriptureMemoryEntry(
                bibleReference: trimmedReference,
                passageText: trimmedPassage,
                isSystemManaged: memorizationSettings.isSystemEnabled
            )
            
            // Handle Add Existing logic
            if selectedMode == .addExisting && memorizationSettings.isSystemEnabled {
                MemorizationEngine.configureExistingEntry(
                        entry: newEntry,
                        phase: selectedPhase,
                        completedCount: completedCount,
                        hasCompletedToday: hasCompletedToday
                    )
            }
            
            // Auto-tag with Bible book
            updateAutoTags(for: newEntry)
            
            modelContext.insert(newEntry)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving Scripture memory entry: \(error)")
        }
    }
    
    private func updateAutoTags(for entry: ScriptureMemoryEntry) {
        // Extract book name from reference (e.g., "John 3:16" -> "John")
        let bookName = extractBookName(from: entry.bibleReference)
        
        // Find matching Bible book tag
        if let bookTag = tagStore.tag(for: bookName) {
            if !entry.tagIDs.contains(bookTag.id) {
                entry.tagIDs.append(bookTag.id)
            }
        }
    }
    
    private func extractBookName(from reference: String) -> String {
        // Simple extraction - gets text before first space or digit
        let components = reference.components(separatedBy: CharacterSet.decimalDigits).first?.trimmingCharacters(in: .whitespaces) ?? ""
        return components.trimmingCharacters(in: CharacterSet(charactersIn: " :"))
    }
}

struct AddScriptureMemoryView_Previews: PreviewProvider {
    static var previews: some View {
        AddScriptureMemoryView()
            .environmentObject(MemorizationSettings())
            .environmentObject(TagStore())
            .modelContainer(for: ScriptureMemoryEntry.self, inMemory: true)
    }
}
