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
    @EnvironmentObject var binderStore: BinderStore
    
    // Entry to edit (nil for new entries)
    let entryToEdit: ScriptureMemoryEntry?
    
    // MARK: - State Variables
    @State private var selectedMode: AddMemoryMode? = nil
    @State private var isInitialized: Bool = false
    @State private var individualVerses: [Int: String] = [:]  // New verse-by-verse input
    @State private var showScripturePicker = false
    
    // Scripture passage selection (updated to work with new sheet)
    @State private var selectedPassages: [ScripturePassageSelection] = []
    @State private var scripturePassage: ScripturePassageSelection = ScripturePassageSelection(bookIndex: -1, chapter: 1, verse: 1, verseEnd: 1)
    
    // Add Existing Entry state
    @State private var selectedPhase: MemorizationPhase = .phase1
    @State private var completedCount: Int = 0
    @State private var hasCompletedToday: Bool = false
    @State private var showPhaseQuestions = false
    
    // Binder selection state
    @State private var showBinderPicker = false
    @State private var selectedBinderIDs: Set<UUID> = []
    
    // Computed property for bible reference string
    private var bibleReference: String {
        if let firstPassage = selectedPassages.first {
            return firstPassage.displayString(bibleBooks: bibleBooks) ?? ""
        }
        return scripturePassage.displayString(bibleBooks: bibleBooks) ?? ""
    }
    
    // Computed properties for verse management
    private var verseNumbers: [Int] {
        if let firstPassage = selectedPassages.first, firstPassage.bookIndex >= 0 {
            return Array(firstPassage.verse...firstPassage.verseEnd)
        }
        guard scripturePassage.bookIndex >= 0 else { return [] }
        return Array(scripturePassage.verse...scripturePassage.verseEnd)
    }
    
    // Update individual verses when scripture passage changes
    private func updateVersesForPassage() {
        let newVerses = verseNumbers
        var updatedVerses: [Int: String] = [:]
        
        // Keep existing text for verses that are still in range
        for verseNum in newVerses {
            updatedVerses[verseNum] = individualVerses[verseNum] ?? ""
        }
        
        individualVerses = updatedVerses
    }
    
    // Binding helper for individual verse text fields
    private func bindingFor(verse: Int) -> Binding<String> {
        return Binding(
            get: { individualVerses[verse] ?? "" },
            set: { individualVerses[verse] = $0 }
        )
    }
    
    // Validation
    private var isValidEntry: Bool {
        !bibleReference.trimmingCharacters(in: .whitespaces).isEmpty &&
        !individualVerses.values.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
    
    // MARK: - Initializer
    init(entryToEdit: ScriptureMemoryEntry? = nil, preselectedBinderID: UUID? = nil) {
        self.entryToEdit = entryToEdit
        // Initialize state immediately for edit mode
        if let entry = entryToEdit {
            let parsedPassage = parseReferenceToPassage(entry.bibleReference)
            _scripturePassage = State(initialValue: parsedPassage)
            _selectedPassages = State(initialValue: [parsedPassage])
            _individualVerses = State(initialValue: entry.individualVerses)
            _isInitialized = State(initialValue: true)
        }
        
        // Initialize binder selection with preselected binder if provided
        if let preselectedBinderID = preselectedBinderID {
            _selectedBinderIDs = State(initialValue: Set([preselectedBinderID]))
        }
    }
    
    // Helper function to parse verse numbers (moved from model for reuse)
    private func parseVerseNumbers(from reference: String) -> [Int] {
        let parts = reference.components(separatedBy: " ")
        guard parts.count >= 2 else { return [1] }
        
        let chapterVerse = parts[1]
        let chapterVerseParts = chapterVerse.components(separatedBy: ":")
        guard chapterVerseParts.count == 2 else { return [1] }
        
        let versePart = chapterVerseParts[1]
        let verseRange = versePart.components(separatedBy: "-")
        
        guard let startVerse = Int(verseRange[0]) else { return [1] }
        
        if verseRange.count > 1, let endVerse = Int(verseRange[1]) {
            return Array(startVerse...endVerse)
        } else {
            return [startVerse]
        }
    }
    
    // Helper function to parse string reference back to passage selection
    private func parseReferenceToPassage(_ reference: String) -> ScripturePassageSelection {
        // More robust parsing that handles multi-word book names
        
        // Find the chapter:verse part (contains colon)
        guard let colonRange = reference.range(of: ":") else {
            return ScripturePassageSelection(bookIndex: -1, chapter: 1, verse: 1, verseEnd: 1)
        }
        
        // Split at the last space before the chapter:verse part
        let beforeColon = String(reference[..<colonRange.lowerBound])
        let afterColon = String(reference[colonRange.upperBound...])
        
        // Find the last space to separate book name from chapter
        guard let lastSpaceRange = beforeColon.range(of: " ", options: .backwards) else {
            return ScripturePassageSelection(bookIndex: -1, chapter: 1, verse: 1, verseEnd: 1)
        }
        
        let bookName = String(beforeColon[..<lastSpaceRange.lowerBound])
        let chapterString = String(beforeColon[lastSpaceRange.upperBound...])
        let chapterVerse = chapterString + ":" + afterColon
        
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
                
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(saveButtonTitle) {
                        saveEntry()
                    }
                    .disabled(!isValidEntry)
                }
            }
        }
        .sheet(isPresented: $showScripturePicker) {
            ScripturePickerSheet(selectedPassages: $selectedPassages, allowMultiple: false)
                .presentationDetents([.large, .medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBinderPicker) {
            BinderPickerSheet(selectedBinderIDs: $selectedBinderIDs)
                .environmentObject(binderStore)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .tint(.appGreenDark)
        .onChange(of: selectedPassages) { oldValue, newValue in
            // Update scripturePassage when selectedPassages changes
            if let firstPassage = newValue.first {
                scripturePassage = firstPassage
                updateVersesForPassage()
            }
        }
        .onChange(of: scripturePassage) { oldValue, newValue in
            // Update individual verses when scripture reference changes
            if oldValue.verse != newValue.verse || oldValue.verseEnd != newValue.verseEnd {
                updateVersesForPassage()
            }
        }
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
            Text("Create a new Scripture flashcard")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            
            entryFormView
        }
    }
    
    private var editEntryView: some View {
        VStack(spacing: 20) {
            Text("Edit your Scripture memory entry")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            entryFormView
        }
        .padding()
        .onAppear {
            initializeEditState()
        }
    }
    
    private var modeSelectionView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Image(systemName: "book.closed.fill")
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
                            Text("Already working on a verse? Set your current progress")
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
                            Image(systemName: "book.closed.fill")
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
                
                // Individual Verse Text Fields
                VStack(alignment: .leading, spacing: 12) {
                    Text("Verse Text")
                        .font(.headline)
                        .foregroundColor(.appGreenDark)
                    
                    if verseNumbers.isEmpty {
                        Text("Select a Bible reference above to add verse text")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .italic()
                            .padding(.vertical, 20)
                    } else {
                        ForEach(verseNumbers, id: \.self) { verseNum in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Verse \(verseNum)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.appGreenDark)
                                
                                ScriptureAutoFillTextField(
                                    text: bindingFor(verse: verseNum),
                                    placeholder: "Enter verse \(verseNum) text... (e.g., John 3:16 for auto-fill)",
                                    axis: .vertical
                                )
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.appGreenDark, lineWidth: 1)
                                )
                                .lineLimit(3, reservesSpace: false)
                            }
                        }
                    }
                }
                
                // Phase Questions (for Add Existing mode)
                if selectedMode == .addExisting && memorizationSettings.isSystemEnabled {
                    phaseQuestionsView
                }
                
                // Binder Selection
                binderSection
                
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
    
    // MARK: - Binder Section
    
    private var binderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Binders")
                .font(.headline)
                .foregroundColor(.appGreenDark)
            
            Button(action: { showBinderPicker = true }) {
                HStack {
                    Text(selectedBinderIDs.isEmpty ? "Add Passage to Binder" : "\(selectedBinderIDs.count) selected")
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
    
    // MARK: - Enhanced Save Entry with Context Diagnostics

    private func saveEntry() {
        let trimmedReference = bibleReference.trimmingCharacters(in: .whitespaces)
        
        // Clean up individual verses - remove empty entries
        let cleanedVerses = individualVerses.compactMapValues { text in
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? nil : trimmed
        }
        
        if let existingEntry = entryToEdit {
            // Update existing entry with new individual verses format
            existingEntry.bibleReference = trimmedReference
            existingEntry.individualVerses = cleanedVerses
            // Keep passageText for backward compatibility (generated from individual verses)
            existingEntry.passageText = cleanedVerses.sorted { $0.key < $1.key }
                .map { "\($0.key) \($0.value)" }
                .joined(separator: " ")
            updateAutoTags(for: existingEntry)
            
            // Update binder associations
            binderStore.updateBinderAssociations(for: existingEntry, selectedBinderIDs: selectedBinderIDs)
            
            do {
                try modelContext.save()
                print("✅ Successfully updated existing entry with individual verses")
                dismiss()
            } catch {
                print("❌ Error updating existing entry: \(error)")
            }
        } else {
            // Create new entry with individual verses format
            let newEntry = ScriptureMemoryEntry(
                bibleReference: trimmedReference,
                passageText: "", // Will be populated from individual verses
                isSystemManaged: memorizationSettings.isSystemEnabled
            )
            
            // Set up new format
            newEntry.individualVerses = cleanedVerses
            // Generate backward-compatible passageText
            newEntry.passageText = cleanedVerses.sorted { $0.key < $1.key }
                .map { "\($0.key) \($0.value)" }
                .joined(separator: " ")
            
            print("Created new entry with:")
            print("- Reference: \(newEntry.bibleReference)")
            print("- Passage: \(newEntry.passageText)")
            print("- System managed: \(newEntry.isSystemManaged)")
            print("- Current phase: \(newEntry.currentPhase)")
            print("- Entry ID: \(newEntry.id)")
            
            // Handle Add Existing logic
            if selectedMode == .addExisting && memorizationSettings.isSystemEnabled {
                print("Configuring as existing entry...")
                MemorizationEngine.configureExistingEntry(
                    entry: newEntry,
                    phase: selectedPhase,
                    completedCount: completedCount,
                    hasCompletedToday: hasCompletedToday
                )
            }
            
            // Auto-tag with Bible book
            updateAutoTags(for: newEntry)
            
            // Insert into context
            modelContext.insert(newEntry)
            
            // Add to selected binders
            for binderID in selectedBinderIDs {
                binderStore.addScriptureMemoryEntry(newEntry, to: binderID)
            }
            print("✅ Inserted entry into model context")
            
            // Immediately query to see if it's visible
            let descriptor = FetchDescriptor<ScriptureMemoryEntry>()
            do {
                let allEntries = try modelContext.fetch(descriptor)
                print("🔍 Immediate query found \(allEntries.count) entries in this context")
                for entry in allEntries {
                    print("  - \(entry.bibleReference) (ID: \(entry.id))")
                }
            } catch {
                print("❌ Error querying immediately: \(error)")
            }
            
            do {
                try modelContext.save()
                print("✅ Successfully saved new entry to database")
                
                // Track analytics for scripture verse addition
                AnalyticsService.shared.trackScriptureVerseAdded(systemEnabled: memorizationSettings.isSystemEnabled)
                
                // Query again after save
                let allEntriesAfterSave = try modelContext.fetch(descriptor)
                print("🔍 Post-save query found \(allEntriesAfterSave.count) entries in this context")
                
                dismiss()
            } catch {
                print("❌ Error saving new entry: \(error)")
                print("Error details: \(error.localizedDescription)")
            }
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
    
    private func initializeEditState() {
        guard let entry = entryToEdit else { return }
        
        // Parse and set scripture passage
        let parsedPassage = parseReferenceToPassage(entry.bibleReference)
        scripturePassage = parsedPassage
        selectedPassages = [parsedPassage]
        individualVerses = entry.individualVerses
        
        // Initialize binder selection for editing
        let entryBinders = binderStore.bindersContaining(scriptureEntryID: entry.id)
        selectedBinderIDs = Set(entryBinders.map { $0.id })
        
        isInitialized = true
    }
}

struct AddScriptureMemoryView_Previews: PreviewProvider {
    static var previews: some View {
        AddScriptureMemoryView()
            .environmentObject(previewMemorizationSettings)
            .environmentObject(previewTagStore)
            .modelContainer(previewContainer)
    }
}
