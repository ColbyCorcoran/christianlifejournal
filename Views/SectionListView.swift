//
//  SectionListView.swift
//  Christian Life Journal
//
//  Updated to use MemorizationEngine for Scripture Memory functionality
//

import SwiftUI
import SwiftData

struct SectionListView: View {
    @Environment(\.modelContext) private var modelContext
    let section: JournalSection
    @Query(sort: \JournalEntry.date, order: .reverse) private var allEntries: [JournalEntry]
    @Query(sort: \ScriptureMemoryEntry.dateAdded, order: .reverse) private var allScriptureEntries: [ScriptureMemoryEntry]
    
    @EnvironmentObject var speakerStore: SpeakerStore
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var memorizationSettings: MemorizationSettings
    
    @State private var showAddEntry = false
    @State private var showEditSheet = false
    @State private var entryToEdit: JournalEntry?
    @State private var showDeleteAlert = false
    @State private var entryToDelete: JournalEntry?
    @State private var scriptureEntryToDelete: ScriptureMemoryEntry?
    
    // Multi-select state
    @State private var isEditing = false
    @State private var selectedEntries: Set<JournalEntry> = []
    @State private var selectedScriptureEntries: Set<ScriptureMemoryEntry> = []
    @State private var showTagPicker = false
    @State private var selectedTagIDs: Set<UUID> = []
    
    // Scripture memorization specific state
    @State private var showAllVerses = false
    
    var entries: [JournalEntry] {
        allEntries.filter { $0.section == section.rawValue }
    }
    
    var scriptureEntries: [ScriptureMemoryEntry] {
        allScriptureEntries
    }
    
    // Use MemorizationEngine for phase grouping (dashboard view)
    var entriesByPhase: (phase1: [ScriptureMemoryEntry], phase2: [ScriptureMemoryEntry], phase3: [ScriptureMemoryEntry]) {
        MemorizationEngine.versesByPhase(entries: scriptureEntries)
    }
    
    // Get memorization statistics
    var memorizationStatistics: MemorizationStatistics {
        MemorizationEngine.getStatistics(entries: scriptureEntries)
    }
    
    // Get completion streak
    var completionStreak: Int {
        MemorizationEngine.calculateCompletionStreak(entries: scriptureEntries)
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.appWhite.ignoresSafeArea()
            
            if section == .scriptureMemorization {
                scriptureMemorizationContent
            } else {
                regularSectionContent
            }
            
            // Floating Add Entry Button
            Button(action: {
                showAddEntry = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.appGreenDark))
                    .shadow(radius: 3)
            }
            .padding(.trailing, 24)
            .padding(.bottom, 32)
            .accessibilityLabel("Add Entry")
        }
        .navigationTitle(section.rawValue)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if section == .scriptureMemorization && memorizationSettings.isSystemEnabled {
                    HStack {
                        Button(showAllVerses ? "Show Dashboard" : "View All Verses") {
                            showAllVerses.toggle()
                        }
                        .font(.caption)
                        .foregroundColor(.appGreenDark)
                        
                        if isEditing {
                            Button("Done") {
                                isEditing = false
                                selectedEntries.removeAll()
                                selectedScriptureEntries.removeAll()
                            }
                        } else {
                            Button("Edit") { isEditing = true }
                        }
                    }
                } else {
                    if isEditing {
                        Button("Done") {
                            isEditing = false
                            selectedEntries.removeAll()
                            selectedScriptureEntries.removeAll()
                        }
                    } else {
                        Button("Edit") { isEditing = true }
                    }
                }
            }
        }
        .alert("Delete Entries?", isPresented: $showDeleteAlert) {
            if section == .scriptureMemorization {
                if isEditing && !selectedScriptureEntries.isEmpty {
                    Button("Delete", role: .destructive) {
                        for entry in selectedScriptureEntries {
                            modelContext.delete(entry)
                        }
                        selectedScriptureEntries.removeAll()
                        isEditing = false
                    }
                } else if let entry = scriptureEntryToDelete {
                    Button("Delete", role: .destructive) {
                        modelContext.delete(entry)
                    }
                }
            } else {
                if isEditing && !selectedEntries.isEmpty {
                    Button("Delete", role: .destructive) {
                        for entry in selectedEntries {
                            modelContext.delete(entry)
                        }
                        selectedEntries.removeAll()
                        isEditing = false
                    }
                } else if let entry = entryToDelete {
                    Button("Delete", role: .destructive) {
                        modelContext.delete(entry)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if section == .scriptureMemorization {
                if isEditing && !selectedScriptureEntries.isEmpty {
                    Text("Are you sure you want to delete the selected scripture entries?")
                } else if let entry = scriptureEntryToDelete {
                    Text("Are you sure you want to delete \"\(entry.bibleReference)\"?")
                } else {
                    Text("")
                }
            } else {
                if isEditing && !selectedEntries.isEmpty {
                    Text("Are you sure you want to delete the selected entries?")
                } else if let entry = entryToDelete {
                    Text("Are you sure you want to delete \"\(entry.title)\"?")
                } else {
                    Text("")
                }
            }
        }
        .sheet(isPresented: $showAddEntry) {
            addEntrySheetView()
        }
        .sheet(isPresented: $showEditSheet) {
            if let entry = entryToEdit {
                addEntrySheetView(entry: entry)
            }
        }
        .onChange(of: showTagPicker) {
            if !showTagPicker && !selectedTagIDs.isEmpty {
                // Add selected tags to all selected entries
                if section == .scriptureMemorization {
                    for entry in selectedScriptureEntries {
                        var tagIDs = entry.tagIDs
                        tagIDs.append(contentsOf: selectedTagIDs.filter { !tagIDs.contains($0) })
                        entry.tagIDs = tagIDs
                    }
                } else {
                    for entry in selectedEntries {
                        var tagIDs = entry.tagIDs
                        tagIDs.append(contentsOf: selectedTagIDs.filter { !tagIDs.contains($0) })
                        entry.tagIDs = tagIDs
                    }
                }
                selectedTagIDs.removeAll()
            }
        }
        .scrollContentBackground(.hidden)
        .onAppear {
            // Clear any stale navigation state
            selectedEntries.removeAll()
            selectedScriptureEntries.removeAll()
            isEditing = false
        }
    }
    
    // MARK: - Scripture Memorization Content
    
    @ViewBuilder
    private var scriptureMemorizationContent: some View {
        VStack(spacing: 0) {
            if memorizationSettings.isSystemEnabled && !showAllVerses {
                // System ON: Dashboard view with phases
                dashboardView
            } else {
                // System OFF or View All Verses: Regular list
                scriptureListView
            }
            
            // Bulk action bar for scripture entries
            if isEditing && !selectedScriptureEntries.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Button(action: { showDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                        Spacer()
                        Button(action: { showTagPicker = true }) {
                            Label("Add Tags", systemImage: "tag.circle.fill")
                                .foregroundColor(.appGreenDark)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.appWhite).shadow(radius: 4))
                    .padding(.horizontal)
                    .padding(.bottom, 90)
                }
                .transition(.move(edge: .bottom))
            }
            
            // Tag picker overlay
            if showTagPicker {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture { showTagPicker = false }
                TagPickerOverlay(
                    isPresented: $showTagPicker,
                    selectedTagIDs: $selectedTagIDs
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(2)
            }
        }
    }
    
    // MARK: - Dashboard View (System ON, Phase View)
    
    @ViewBuilder
    private var dashboardView: some View {
        VStack(spacing: 0) {
            // Statistics header
            statisticsHeaderView
            
            let phases = entriesByPhase
            
            List {
                // Phase 1 Section
                if !phases.phase1.isEmpty {
                    Section(header: phaseHeaderView(phase: .phase1, count: phases.phase1.count)) {
                        ForEach(phases.phase1) { entry in
                            scriptureRowView(entry: entry, showPhase: false)
                        }
                    }
                }
                
                // Phase 2 Section
                if !phases.phase2.isEmpty {
                    Section(header: phaseHeaderView(phase: .phase2, count: phases.phase2.count)) {
                        ForEach(phases.phase2) { entry in
                            scriptureRowView(entry: entry, showPhase: false)
                        }
                    }
                }
                
                // Phase 3 Section
                if !phases.phase3.isEmpty {
                    Section(header: phaseHeaderView(phase: .phase3, count: phases.phase3.count)) {
                        ForEach(phases.phase3) { entry in
                            scriptureRowView(entry: entry, showPhase: false)
                        }
                    }
                }
                
                // Empty state if no verses need completion today
                if phases.phase1.isEmpty && phases.phase2.isEmpty && phases.phase3.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.green)
                            Text("All caught up!")
                                .font(.headline)
                                .foregroundColor(.appGreenDark)
                            Text("No verses need completion today")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if !scriptureEntries.isEmpty {
                                Text("Tap 'View All Verses' to see your complete collection")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appWhite)
        }
    }
    
    // MARK: - Statistics Header
    
    @ViewBuilder
    private var statisticsHeaderView: some View {
        let stats = memorizationStatistics
        
        if stats.totalVerses > 0 {
            VStack(spacing: 12) {
                // Main statistics row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(stats.totalVerses)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appGreenDark)
                        Text("Total Verses")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("\(stats.phase1Verses)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Text("Phase 1")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("\(stats.phase2Verses)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                        Text("Phase 2")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("\(stats.phase3Verses)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        Text("Phase 3")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(stats.versesNeedingCompletionToday)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("Due Today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Streak information
                if completionStreak > 0 {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(completionStreak) day streak!")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appGreenPale.opacity(0.3))
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Scripture List View (All Verses)
    
    @ViewBuilder
    private var scriptureListView: some View {
        List(selection: $selectedScriptureEntries) {
            ForEach(scriptureEntries) { entry in
                scriptureRowView(entry: entry, showPhase: memorizationSettings.isSystemEnabled)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appWhite)
        .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
    }
    
    @ViewBuilder
    private func phaseHeaderView(phase: MemorizationPhase, count: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(phase.rawValue)
                    .font(.headline)
                    .foregroundColor(.appGreenDark)
                Text(phase.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(count) verse\(count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appGreenPale.opacity(0.3))
                )
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func scriptureRowView(entry: ScriptureMemoryEntry, showPhase: Bool) -> some View {
        if isEditing {
            HStack {
                Image(systemName: selectedScriptureEntries.contains(entry) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedScriptureEntries.contains(entry) ? .appGreenDark : .gray)
                
                ScriptureListRow(
                    entry: entry,
                    showPhase: showPhase,
                    onDelete: {
                        scriptureEntryToDelete = entry
                        showDeleteAlert = true
                    }
                )
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if selectedScriptureEntries.contains(entry) {
                    selectedScriptureEntries.remove(entry)
                } else {
                    selectedScriptureEntries.insert(entry)
                }
            }
        } else {
            ScriptureListRow(
                entry: entry,
                showPhase: showPhase,
                onDelete: {
                    scriptureEntryToDelete = entry
                    showDeleteAlert = true
                }
            )
        }
    }
    
    // MARK: - Regular Section Content
    
    @ViewBuilder
    private var regularSectionContent: some View {
        VStack(spacing: 0) {
            List(selection: $selectedEntries) {
                ForEach(entries) { entry in
                    if isEditing {
                        HStack {
                            Image(systemName: selectedEntries.contains(entry) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedEntries.contains(entry) ? .appGreenDark : .gray)
                            SectionListRow(
                                entry: entry,
                                section: section,
                                onEdit: {
                                    entryToEdit = entry
                                    showEditSheet = true
                                },
                                onDelete: {
                                    entryToDelete = entry
                                    showDeleteAlert = true
                                }
                            )
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
                        SectionListRow(
                            entry: entry,
                            section: section,
                            onEdit: {
                                entryToEdit = entry
                                showEditSheet = true
                            },
                            onDelete: {
                                entryToDelete = entry
                                showDeleteAlert = true
                            }
                        )
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.appWhite)
            .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
            
            // Bulk action bar for regular entries
            if isEditing && !selectedEntries.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Button(action: { showDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                        Spacer()
                        Button(action: { showTagPicker = true }) {
                            Label("Add Tags", systemImage: "tag.circle.fill")
                                .foregroundColor(.appGreenDark)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.appWhite).shadow(radius: 4))
                    .padding(.horizontal)
                    .padding(.bottom, 90)
                }
                .transition(.move(edge: .bottom))
            }
            
            // Tag picker overlay
            if showTagPicker {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture { showTagPicker = false }
                TagPickerOverlay(
                    isPresented: $showTagPicker,
                    selectedTagIDs: $selectedTagIDs
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(2)
            }
        }
    }

    @ViewBuilder
    private func addEntrySheetView(entry: JournalEntry? = nil) -> some View {
        if section == .scriptureMemorization {
            // For scripture memorization, always use the scripture-specific view
            AddScriptureMemoryView()
                .environmentObject(memorizationSettings)
        } else {
            // For other sections, use existing logic
            switch JournalSection(rawValue: entry?.section ?? section.rawValue) {
            case .personalTime:
                AddPersonalTimeView(entryToEdit: entry, section: section)
            case .sermonNotes:
                AddSermonNotesView(entryToEdit: entry, section: section)
            case .scriptureMemorization, .prayerJournal, .groupNotes, .other, .none:
                AddEntryView(entryToEdit: entry, section: section)
            }
        }
    }
}

// MARK: - Scripture List Row (Updated)

struct ScriptureListRow: View {
    let entry: ScriptureMemoryEntry
    let showPhase: Bool
    let onDelete: () -> Void

    var body: some View {
        NavigationLink(value: DashboardNav.scriptureEntry(entry.id)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.bibleReference)
                        .font(.headline)
                    
                    HStack {
                        Text(formattedDate(entry.dateAdded))
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if showPhase {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(entry.currentPhase.rawValue)
                                .font(.caption)
                                .foregroundColor(.appGreenDark)
                        }
                    }
                }
                
                Spacer()
                
                // Completion indicator using engine logic
                CompletionStatusView(entry: entry)
            }
            .padding(.vertical, 4)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Completion Status Component

struct CompletionStatusView: View {
    let entry: ScriptureMemoryEntry
    
    var body: some View {
        let needsCompletion = entry.needsCompletionOn(date: Date())
        let calendar = Calendar.current
        let hasCompletedToday = entry.lastCompletionDate.map {
            calendar.isDate($0, inSameDayAs: Date())
        } ?? false
        
        if needsCompletion {
            VStack {
                Image(systemName: "circle")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("Due")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        } else if hasCompletedToday && entry.isSystemManaged {
            VStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("Done")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        } else {
            // Verse exists but doesn't need completion or system is OFF
            EmptyView()
        }
    }
}

// MARK: - Regular Section Row (Unchanged)

struct SectionListRow: View {
    let entry: JournalEntry
    let section: JournalSection
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        NavigationLink(value: DashboardNav.entry(entry.id)) {
            VStack(alignment: .leading, spacing: 4) {
                if section == .personalTime {
                    Text(formattedDate(entry.date))
                        .font(.headline)
                    Text(entry.scripture?.components(separatedBy: ";").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Text(entry.title)
                        .font(.headline)
                    Text(formattedDate(entry.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 4)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(Color.appGreenDark)
        }
    }
}

// MARK: - Preview

struct SectionListView_Previews: PreviewProvider {
    static var previews: some View {
        SectionListView(section: .scriptureMemorization)
            .modelContainer(for: [JournalEntry.self, ScriptureMemoryEntry.self], inMemory: true)
            .environmentObject(MemorizationSettings())
            .environmentObject(SpeakerStore())
            .environmentObject(TagStore())
    }
}
