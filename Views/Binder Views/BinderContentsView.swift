 //
//  BinderContentsView.swift
//  Christian Life Journal
//
//  View for displaying all entries within a specific binder
//

import SwiftUI
import SwiftData

struct BinderContentsView: View {
    let binder: Binder
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var binderStore: BinderStore
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var speakerStore: SpeakerStore
    @EnvironmentObject var memorizationSettings: MemorizationSettings
    @EnvironmentObject var prayerCategoryStore: PrayerCategoryStore
    @EnvironmentObject var prayerRequestStore: PrayerRequestStore
    
    @Query private var allJournalEntries: [JournalEntry]
    @Query private var allScriptureEntries: [ScriptureMemoryEntry]
    
    @State private var showEditBinder = false
    @State private var selectedEntry: BinderEntry?
    
    // Multi-select state
    @State private var isEditing = false
    @State private var selectedEntries: Set<BinderEntry> = []
    @State private var showBulkActions = false
    @State private var showBulkBinderPicker = false
    @State private var showBulkTagPicker = false
    @State private var showRemoveConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var bulkSelectedTagIDs: Set<UUID> = []
    @State private var showSuccessAlert = false
    @State private var successMessage = ""
    
    // Quick add state
    @State private var showQuickAdd = false
    @State private var presentedSection: IdentifiableSection?
    
    init(binder: Binder) {
        self.binder = binder
        // Initialize queries to fetch all entries
        self._allJournalEntries = Query(sort: \JournalEntry.date, order: .reverse)
        self._allScriptureEntries = Query(sort: \ScriptureMemoryEntry.dateAdded, order: .reverse)
    }
    
    var body: some View {
        ZStack {
            Color.appWhite.ignoresSafeArea()
            
            if binderEntries.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Binder Header
                        binderHeaderCard
                        
                        // Entries by Section
                        entriesBySection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            
            // Floating Add Button (only show when not editing and has entries)
            if !isEditing && !binderEntries.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showQuickAdd = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.appGreenDark))
                                .shadow(radius: 3)
                        }
                        .accessibilityLabel("Quick Add")
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .navigationBarTrailing) {
                    let selectedCount = selectedEntries.count
                    if selectedCount > 0 {
                        Button("Actions (\(selectedCount))") {
                            showBulkActions = true
                        }
                        .foregroundColor(.appGreenDark)
                    } else {
                        EmptyView()
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if isEditing {
                        Button("Done") {
                            isEditing = false
                            selectedEntries.removeAll()
                        }
                        .foregroundColor(.appGreenDark)
                    } else {
                        Button("Edit Binder") {
                            showEditBinder = true
                        }
                        .foregroundColor(.appGreenDark)
                        
                        if !binderEntries.isEmpty {
                            Button("Select") {
                                isEditing = true
                            }
                            .foregroundColor(.appGreenDark)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showEditBinder) {
            EditBinderView(binder: binder)
                .environmentObject(binderStore)
        }
        .sheet(item: Binding<BinderEntry?>(
            get: { selectedEntry },
            set: { _ in selectedEntry = nil }
        )) { entry in
            NavigationStack {
                switch entry {
                case .journalEntry(let journalEntry):
                    JournalEntryDetailView(entry: journalEntry, showBinderFunctionality: false)
                        .environmentObject(tagStore)
                        .environmentObject(speakerStore)
                        .environmentObject(memorizationSettings)
                        .environmentObject(prayerCategoryStore)
                        .environmentObject(prayerRequestStore)
                        .environmentObject(binderStore)
                case .scriptureEntry(let scriptureEntry):
                    ScriptureFlashcardView(entry: scriptureEntry, embedInNavigationView: false, showBinderFunctionality: false)
                        .environmentObject(tagStore)
                        .environmentObject(speakerStore)
                        .environmentObject(memorizationSettings)
                        .environmentObject(binderStore)
                        .environmentObject(prayerCategoryStore)
                        .environmentObject(prayerRequestStore)
                case .prayerRequest(let prayerRequest):
                    PrayerRequestDetailView(prayerRequest: prayerRequest, showBinderFunctionality: false)
                        .environmentObject(tagStore)
                        .environmentObject(speakerStore)
                        .environmentObject(memorizationSettings)
                        .environmentObject(prayerCategoryStore)
                        .environmentObject(prayerRequestStore)
                        .environmentObject(binderStore)
                }
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBulkActions) {
            BinderBulkActionsSheet(
                selectedCount: selectedEntries.count,
                binderName: binder.name,
                isPresented: $showBulkActions,
                onRemoveFromBinder: { showRemoveConfirmation = true },
                onAddTags: { showBulkTagPicker = true },
                onDelete: { showDeleteConfirmation = true }
            )
        }
        .sheet(isPresented: $showBulkTagPicker) {
            NavigationStack {
                VStack {
                    // Custom navigation bar
                    HStack {
                        Button("Cancel") {
                            bulkSelectedTagIDs.removeAll()
                            showBulkTagPicker = false
                        }
                        .foregroundColor(.appGreenDark)
                        
                        Spacer()
                        
                        Text("Add Tags")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Apply") {
                            // Apply tags when Apply is pressed
                            if !bulkSelectedTagIDs.isEmpty {
                                for entry in selectedEntries {
                                    switch entry {
                                    case .journalEntry(let journalEntry):
                                        for tagID in bulkSelectedTagIDs {
                                            if !journalEntry.tagIDs.contains(tagID) {
                                                journalEntry.tagIDs.append(tagID)
                                            }
                                        }
                                    case .scriptureEntry(let scriptureEntry):
                                        for tagID in bulkSelectedTagIDs {
                                            if !scriptureEntry.tagIDs.contains(tagID) {
                                                scriptureEntry.tagIDs.append(tagID)
                                            }
                                        }
                                    case .prayerRequest(let prayerRequest):
                                        for tagID in bulkSelectedTagIDs {
                                            if !prayerRequest.tagIDs.contains(tagID) {
                                                prayerRequest.tagIDs.append(tagID)
                                            }
                                        }
                                    }
                                }
                                
                                do {
                                    try modelContext.save()
                                    
                                    // Show success message
                                    let tagCount = bulkSelectedTagIDs.count
                                    let entryCount = selectedEntries.count
                                    let tagText = tagCount == 1 ? "tag" : "tags"
                                    let entryText = entryCount == 1 ? "entry" : "entries"
                                    
                                    successMessage = "Added \(tagCount) \(tagText) to \(entryCount) \(entryText)"
                                    showSuccessAlert = true
                                    
                                } catch {
                                    print("Error saving bulk tag changes: \(error)")
                                }
                                
                                bulkSelectedTagIDs.removeAll()
                                selectedEntries.removeAll()
                                isEditing = false
                            }
                            showBulkTagPicker = false
                        }
                        .disabled(bulkSelectedTagIDs.isEmpty)
                        .foregroundColor(bulkSelectedTagIDs.isEmpty ? .gray : .appGreenDark)
                    }
                    .padding()
                    
                    Divider()
                    
                    TagPickerSheet(selectedTagIDs: $bulkSelectedTagIDs)
                        .environmentObject(tagStore)
                }
                .background(Color.appWhite.ignoresSafeArea())
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") { }
        } message: {
            Text(successMessage)
        }
        .confirmationDialog(
            "Remove from \"\(binder.name)\"?",
            isPresented: $showRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                removeSelectedEntriesFromBinder()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Remove \(selectedEntries.count) \(selectedEntries.count == 1 ? "entry" : "entries") from this binder? The \(selectedEntries.count == 1 ? "entry" : "entries") will remain in \(selectedEntries.count == 1 ? "its" : "their") original location.")
        }
        .confirmationDialog(
            "Delete \(selectedEntries.count) \(selectedEntries.count == 1 ? "entry" : "entries")?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteSelectedEntries()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $showQuickAdd) {
            BinderQuickAddMenuView(
                binderName: binder.name,
                isPresented: $showQuickAdd,
                presentedSection: $presentedSection
            )
        }
        .sheet(item: $presentedSection) { identifiableSection in
            Group {
                switch identifiableSection.section {
                case .personalTime:
                    AddPersonalTimeView(section: .personalTime, preselectedBinderID: binder.id)
                        .environmentObject(tagStore)
                        .environmentObject(binderStore)
                case .scriptureMemorization:
                    AddScriptureMemoryView(preselectedBinderID: binder.id)
                        .environmentObject(tagStore)
                        .environmentObject(binderStore)
                        .environmentObject(memorizationSettings)
                case .prayerRequest:
                    AddPrayerRequestView(preselectedBinderID: binder.id)
                        .environmentObject(tagStore)
                        .environmentObject(binderStore)
                        .environmentObject(prayerCategoryStore)
                case .prayerJournal:
                    AddEntryView(entryToEdit: nil, section: .prayerJournal, preselectedBinderID: binder.id)
                        .environmentObject(tagStore)
                        .environmentObject(binderStore)
                        .environmentObject(speakerStore)
                case .sermonNotes:
                    AddSermonNotesView(preselectedBinderID: binder.id)
                        .environmentObject(tagStore)
                        .environmentObject(binderStore)
                        .environmentObject(speakerStore)
                case .groupNotes:
                    AddEntryView(entryToEdit: nil, section: .groupNotes, preselectedBinderID: binder.id)
                        .environmentObject(tagStore)
                        .environmentObject(binderStore)
                        .environmentObject(speakerStore)
                case .other:
                    AddEntryView(entryToEdit: nil, section: .other, preselectedBinderID: binder.id)
                        .environmentObject(tagStore)
                        .environmentObject(binderStore)
                        .environmentObject(speakerStore)
                }
            }
            .environment(\.modelContext, modelContext)
        }
    }
    
    // MARK: - Bulk Action Methods
    
    private func removeSelectedEntriesFromBinder() {
        for entry in selectedEntries {
            switch entry {
            case .journalEntry(let journalEntry):
                binderStore.removeJournalEntry(journalEntry.id, fromBinder: binder.id)
            case .scriptureEntry(let scriptureEntry):
                binderStore.removeScriptureEntry(scriptureEntry.id, fromBinder: binder.id)
            case .prayerRequest(let prayerRequest):
                binderStore.removePrayerRequest(prayerRequest.id, fromBinder: binder.id)
            }
        }
        
        let entryCount = selectedEntries.count
        successMessage = "Removed \(entryCount) \(entryCount == 1 ? "entry" : "entries") from \"\(binder.name)\""
        showSuccessAlert = true
        
        selectedEntries.removeAll()
        isEditing = false
    }
    
    private func deleteSelectedEntries() {
        for entry in selectedEntries {
            switch entry {
            case .journalEntry(let journalEntry):
                modelContext.delete(journalEntry)
            case .scriptureEntry(let scriptureEntry):
                modelContext.delete(scriptureEntry)
            case .prayerRequest(let prayerRequest):
                prayerRequestStore.removePrayerRequest(withId: prayerRequest.id)
            }
        }
        
        // Only save for journal and scripture entries (prayer requests are handled by the store)
        let hasJournalOrScriptureEntries = selectedEntries.contains { entry in
            switch entry {
            case .journalEntry(_), .scriptureEntry(_):
                return true
            case .prayerRequest(_):
                return false
            }
        }
        
        if hasJournalOrScriptureEntries {
            do {
                try modelContext.save()
            } catch {
                print("Error deleting entries: \(error)")
            }
        }
        
        selectedEntries.removeAll()
        isEditing = false
    }
    
    // MARK: - Data Processing
    
    private var binderEntries: [BinderEntry] {
        var entries: [BinderEntry] = []
        
        // Add journal entries
        for entryID in binder.journalEntryIDs {
            if let journalEntry = allJournalEntries.first(where: { $0.id == entryID }) {
                entries.append(.journalEntry(journalEntry))
            }
        }
        
        // Add scripture entries
        for entryID in binder.scriptureEntryIDs {
            if let scriptureEntry = allScriptureEntries.first(where: { $0.id == entryID }) {
                entries.append(.scriptureEntry(scriptureEntry))
            }
        }
        
        // Add prayer requests
        for requestID in binder.prayerRequestIDs {
            if let prayerRequest = prayerRequestStore.prayerRequests.first(where: { $0.id == requestID }) {
                entries.append(.prayerRequest(prayerRequest))
            }
        }
        
        // Sort by date, newest first
        return entries.sorted { $0.date > $1.date }
    }
    
    private var groupedEntries: [(String, [BinderEntry])] {
        let grouped = Dictionary(grouping: binderEntries) { entry in
            entry.sectionName
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
    
    // MARK: - View Components
    
    private var binderHeaderCard: some View {
        HStack(alignment: .top, spacing: 0) {
            // Vertical color strip
            Rectangle()
                .fill(binder.color)
                .frame(width: 4)
                .padding(.trailing, 12)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(binder.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.appGreenDark)
                    
                    Spacer()
                
                Text(binder.totalEntryCount == 1 ? "1 entry" : "\(binder.totalEntryCount) entries")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.appGreenDark)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.appGreenPale.opacity(0.3))
                    )
            }
            
            if let description = binder.binderDescription, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
                Text("Created \(binder.formattedDateCreated)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appGreenPale.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appGreenDark.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var entriesBySection: some View {
        LazyVStack(spacing: 20) {
            ForEach(groupedEntries, id: \.0) { sectionName, entries in
                VStack(alignment: .leading, spacing: 12) {
                    // Section Header
                    HStack {
                        Text(sectionName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.appGreenDark)
                        
                        Spacer()
                        
                        Text("\(entries.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    // Entries in this section
                    LazyVStack(spacing: 12) {
                        ForEach(entries) { entry in
                            if isEditing {
                                HStack {
                                    Image(systemName: selectedEntries.contains(entry) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedEntries.contains(entry) ? .appGreenDark : .gray)
                                        .font(.title3)
                                    
                                    BinderEntryCard(entry: entry) {
                                        // In editing mode, toggle selection instead of showing detail
                                        if selectedEntries.contains(entry) {
                                            selectedEntries.remove(entry)
                                        } else {
                                            selectedEntries.insert(entry)
                                        }
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if selectedEntries.contains(entry) {
                                        selectedEntries.remove(entry)
                                    } else {
                                        selectedEntries.insert(entry)
                                    }
                                }
                            } else {
                                BinderEntryCard(entry: entry) {
                                    selectedEntry = entry
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundColor(.appGreenMedium.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Empty Binder")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.appGreenDark)
                
                Text("This binder doesn't contain any entries yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Add entry button for empty state
                Button(action: {
                    showQuickAdd = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Add Entry")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.appGreenDark)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .padding(.top, 8)
            }
        }
        .frame(maxHeight: .infinity)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Supporting Types

enum BinderEntry: Identifiable, Hashable {
    case journalEntry(JournalEntry)
    case scriptureEntry(ScriptureMemoryEntry)
    case prayerRequest(PrayerRequest)
    
    var id: UUID {
        switch self {
        case .journalEntry(let entry): return entry.id
        case .scriptureEntry(let entry): return entry.id
        case .prayerRequest(let entry): return entry.id
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: BinderEntry, rhs: BinderEntry) -> Bool {
        return lhs.id == rhs.id
    }
    
    var title: String {
        switch self {
        case .journalEntry(let entry):
            return entry.title.isEmpty ? (entry.scripture ?? "Untitled") : entry.title
        case .scriptureEntry(let entry):
            return entry.bibleReference
        case .prayerRequest(let entry):
            return entry.title.isEmpty ? "Prayer Request" : entry.title
        }
    }
    
    var date: Date {
        switch self {
        case .journalEntry(let entry): return entry.date
        case .scriptureEntry(let entry): return entry.dateAdded
        case .prayerRequest(let entry): return entry.dateAdded
        }
    }
    
    var sectionName: String {
        switch self {
        case .journalEntry(let entry):
            return JournalSection(rawValue: entry.section)?.entryTypeName ?? entry.section
        case .scriptureEntry(_):
            return JournalSection.scriptureMemorization.entryTypeName
        case .prayerRequest(_):
            return JournalSection.prayerRequest.entryTypeName
        }
    }
    
    var iconName: String {
        switch self {
        case .journalEntry(let entry):
            if let section = JournalSection(rawValue: entry.section) {
                switch section {
                case .personalTime: return "person.circle"
                case .sermonNotes: return "mic.fill"
                case .prayerJournal: return "book.pages.fill"
                case .groupNotes: return "person.2.fill"
                case .other: return "doc.fill"
                default: return "doc.text"
                }
            }
            return "doc.text"
        case .scriptureEntry(_): return "book.closed.fill"
        case .prayerRequest(_): return "heart.fill"
        }
    }
}

// MARK: - Binder Entry Card

struct BinderEntryCard: View {
    let entry: BinderEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Type icon
                Image(systemName: entry.iconName)
                    .font(.title3)
                    .foregroundColor(.appGreenDark)
                    .frame(width: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        HStack {
                            Text(formattedDate(entry.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(entry.sectionName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.appGreenLight.opacity(0.3))
                                )
                                .foregroundColor(.appGreenDark)
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Edit Binder View

struct EditBinderView: View {
    let binder: Binder
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var binderStore: BinderStore
    
    @State private var name: String
    @State private var description: String
    @State private var selectedColor: Color
    @State private var showingDeleteConfirmation = false
    
    // Predefined color options (matching Create Binder View)
    private let colorOptions: [Color] = [
        Color(hex: "#4A7C59"), // appGreenMedium
        Color(hex: "#8B6B4A"), // Muted warm brown
        Color(hex: "#9AB6C7"), // Light steel blue  
        Color(hex: "#5B7A9A"), // Muted blue
        Color(hex: "#8B7A9A"), // Muted purple
        Color(hex: "#B5A56B"), // Light muted gold
        Color(hex: "#9A5B5B"), // Muted red
        Color(hex: "#6B6B6B")  // Muted gray
    ]
    
    init(binder: Binder) {
        self.binder = binder
        self._name = State(initialValue: binder.name)
        self._description = State(initialValue: binder.binderDescription ?? "")
        self._selectedColor = State(initialValue: binder.color)
    }
    
    private var isValidBinder: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var colorSelectionGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
            ForEach(colorOptions, id: \.self) { color in
                colorSelectionButton(for: color)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func colorSelectionButton(for color: Color) -> some View {
        Button(action: {
            selectedColor = color
        }) {
            ZStack {
                // Consistent frame size for all buttons
                Circle()
                    .fill(Color.clear)
                    .frame(width: 52, height: 52)
                
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)
            
                if selectedColor == color {
                    Circle()
                        .stroke(Color.appGreenDark, lineWidth: 3)
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Binder Name", text: $name)
                        .font(.body)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .font(.body)
                        .lineLimit(3...6)
                } header: {
                    Text("Binder Details")
                } footer: {
                    Text("Choose a descriptive name for your binder.")
                }
                
                Section {
                    colorSelectionGrid
                } header: {
                    Text("Color")
                } footer: {
                    Text("Select a color to help identify this binder.")
                }
                
                Section {
                    HStack {
                        Circle()
                            .fill(selectedColor)
                            .frame(width: 20, height: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name.isEmpty ? "Binder Name" : name)
                                .font(.headline)
                                .foregroundColor(name.isEmpty ? .secondary : .primary)
                            
                            if !description.isEmpty {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Preview")
                }
                
                Section {
                    Button(role: .destructive, action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Binder")
                        }
                    }
                } footer: {
                    Text("Deleting this binder will not delete the entries it contains. The entries will remain in their original locations.")
                }
            }
            .navigationTitle("Edit Binder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.appGreenDark)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBinder()
                    }
                    .foregroundColor(.appGreenDark)
                    .disabled(!isValidBinder)
                }
            }
            .confirmationDialog(
                "Delete \"\(binder.name)\"?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Binder", role: .destructive) {
                    deleteBinder()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This binder will be permanently deleted. The entries it contains will remain in their original locations.")
            }
        }
    }
    
    private func saveBinder() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Update the binder object directly
        binder.name = trimmedName
        binder.binderDescription = trimmedDescription.isEmpty ? nil : trimmedDescription
        binder.colorHex = selectedColor.toHex()
        
        binderStore.updateBinder(binder)
        
        dismiss()
    }
    
    private func deleteBinder() {
        binderStore.deleteBinder(withId: binder.id)
        dismiss()
    }
}

// MARK: - Binder Bulk Actions Sheet

struct BinderBulkActionsSheet: View {
    let selectedCount: Int
    let binderName: String
    @Binding var isPresented: Bool
    
    let onRemoveFromBinder: () -> Void
    let onAddTags: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.appGreenDark)
                            .font(.title3)
                        Text("Bulk Actions")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.appGreenDark)
                    }
                    
                    Text("\(selectedCount) binder \(selectedCount == 1 ? "entry" : "entries") selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 0)
            }
            .listRowBackground(Color.appGreenPale.opacity(0.1))
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            
            Section("Actions") {
                Button(action: {
                    onRemoveFromBinder()
                    isPresented = false
                }) {
                    actionRowView(
                        icon: "books.vertical.circle",
                        title: "Remove from \"\(binderName)\"",
                        subtitle: "Remove from this binder (entries remain in original location)",
                        isDestructive: true
                    )
                }
                
                Button(action: {
                    onAddTags()
                    isPresented = false
                }) {
                    actionRowView(
                        icon: "tag.circle.fill",
                        title: "Add Tags",
                        subtitle: "Apply tags to all selected entries"
                    )
                }
                
                Button(action: {
                    onDelete()
                    isPresented = false
                }) {
                    actionRowView(
                        icon: "trash",
                        title: "Delete",
                        subtitle: "Permanently remove all selected entries",
                        isDestructive: true
                    )
                }
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
        .listSectionSpacing(.compact)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder
    private func actionRowView(icon: String, title: String, subtitle: String, isDestructive: Bool = false) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isDestructive ? .red : .appGreenDark)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Binder Quick Add Menu View

struct BinderQuickAddMenuView: View {
    let binderName: String
    @Binding var isPresented: Bool
    @Binding var presentedSection: IdentifiableSection?
    
    private var entryTypes: [(section: JournalSection, icon: String)] {
        [
            (.personalTime, "person.circle"),
            (.scriptureMemorization, "book.closed.fill"),
            (.prayerRequest, "heart.fill"),
            (.prayerJournal, "book.pages.fill"),
            (.sermonNotes, "mic.fill"),
            (.groupNotes, "person.2.fill"),
            (.other, "doc.fill")
        ]
    }
    
    // Use the same color scheme as CardSectionView
    private func accentColor(for section: JournalSection) -> Color {
        switch section {
        case .personalTime: return .appGreenDark
        case .scriptureMemorization: return .appGreen
        case .prayerJournal: return .appGreenMedium
        case .prayerRequest: return .appGreenMedium
        case .sermonNotes: return .appGreenMid
        case .groupNotes: return .appGreenLight
        case .other: return .appGreenPale
        }
    }
    
    var body: some View {
        List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.appGreenDark)
                                .font(.title2)
                            Text("Add to \"\(binderName)\"")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.appGreenDark)
                        }
                        
                        Text("Create new content that will be automatically added to this binder")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.appGreenPale.opacity(0.1))
                
                Section("Entry Types") {
                    ForEach(entryTypes, id: \.section) { entryType in
                        Button(action: {
                            presentedSection = IdentifiableSection(section: entryType.section)
                            isPresented = false
                        }) {
                            HStack {
                                Image(systemName: entryType.icon)
                                    .foregroundColor(accentColor(for: entryType.section))
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(width: 24, height: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entryType.section.entryTypeName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text(descriptionFor(entryType.section))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listSectionSpacing(.compact)
            .presentationDragIndicator(.visible)
    }
    
    private func descriptionFor(_ section: JournalSection) -> String {
        switch section {
        case .personalTime:
            return "Record personal devotions and reflections"
        case .scriptureMemorization:
            return "Add verses to memorize with flashcard style"
        case .prayerRequest:
            return "Track prayer requests and answered prayers"
        case .prayerJournal:
            return "Document prayer thoughts and spiritual insights"
        case .sermonNotes:
            return "Take notes during sermons and teachings"
        case .groupNotes:
            return "Record insights from group discussions"
        case .other:
            return "Document miscellaneous thoughts"
        }
    }
}

// MARK: - Color Extension

extension Color {
    func toHex() -> String {
        // Convert SwiftUI Color to UIColor then to hex
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let redInt = Int(red * 255)
        let greenInt = Int(green * 255)
        let blueInt = Int(blue * 255)
        
        return String(format: "#%02X%02X%02X", redInt, greenInt, blueInt)
    }
}

// MARK: - Preview

struct BinderContentsView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBinder = Binder(name: "Romans Study", binderDescription: "13-week study through Romans")
        
        NavigationStack {
            BinderContentsView(binder: sampleBinder)
                .environmentObject(previewBinderStore)
                .environmentObject(previewTagStore)
                .environmentObject(previewSpeakerStore)
                .environmentObject(previewMemorizationSettings)
                .environmentObject(previewPrayerCategoryStore)
                .environmentObject(previewPrayerRequestStore)
                .modelContainer(previewContainer)
        }
    }
}
