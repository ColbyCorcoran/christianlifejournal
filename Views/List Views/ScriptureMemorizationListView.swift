//
//  ScriptureMemorizationListView.swift
//  Christian Life Journal
//
//  Created by Claude on 8/15/25.
//

import SwiftUI
import SwiftData

struct ScriptureMemorizationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var memorizationSettings: MemorizationSettings
    @EnvironmentObject var binderStore: BinderStore
    
    // State for filtering and search
    @State private var searchText = ""
    @State private var selectedPhase: MemorizationPhase? = nil
    
    // State for sheets and view modes
    @State private var showAddSheet = false
    @State private var showAllVerses = false
    @State private var entryToEdit: ScriptureMemoryEntry?
    
    // Bulk selection state
    @State private var isEditing = false
    @State private var selectedEntries: Set<ScriptureMemoryEntry> = []
    @State private var showBulkActions = false
    @State private var showBulkBinderPicker = false
    @State private var showDeleteConfirmation = false
    
    // Individual entry actions
    @State private var showIndividualDeleteConfirmation = false
    @State private var entryToDelete: ScriptureMemoryEntry?
    
    // SwiftData query for Scripture Memory entries
    @Query(
        sort: \ScriptureMemoryEntry.dateAdded,
        order: .reverse
    ) var allScriptureEntries: [ScriptureMemoryEntry]
    
    // Filtered entries based on search and filters
    var filteredEntries: [ScriptureMemoryEntry] {
        var entries = allScriptureEntries
        
        // Apply phase filter
        if let phase = selectedPhase {
            entries = entries.filter { $0.currentPhase == phase }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                entry.passageText.localizedCaseInsensitiveContains(searchText) ||
                entry.bibleReference.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return entries
    }
    
    // Use MemorizationEngine for phase grouping (dashboard view)
    var entriesByPhase: (phase1: [ScriptureMemoryEntry], phase2: [ScriptureMemoryEntry], phase3: [ScriptureMemoryEntry]) {
        let filtered = filteredEntries
        return MemorizationEngine.versesByPhase(entries: filtered)
    }
    
    // Get memorization statistics
    var memorizationStatistics: MemorizationStatistics {
        MemorizationEngine.getStatistics(entries: filteredEntries)
    }
    
    // Build filter groups for the filter chip section
    var filterGroups: [FilterGroup] {
        var groups: [FilterGroup] = []
        
        // Add memorization phase filters
        let phaseGroup = MemorizationPhaseFilterBuilder.buildPhaseFilters(
            selectedPhase: selectedPhase,
            onPhaseSelected: { phase in
                selectedPhase = phase
            }
        )
        groups.append(phaseGroup)
        
        return groups
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section (non-scrolling)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "book.closed.fill")
                        .font(.title2)
                        .foregroundColor(.appGreenDark)
                    Text("Scripture Memorization")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.appGreenDark)
                }
                
                Text("Add verses to memorize with flashcard style")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.bottom, 20)
            .background(Color.appWhite)
            
            // Main content area
            VStack(spacing: 0) {
                if memorizationSettings.isSystemEnabled && !showAllVerses {
                    // System ON: Dashboard view with phases
                    dashboardView
                } else {
                    // System OFF or View All Verses: Regular list
                    scriptureListView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appWhite)
            
            // Fixed bottom search section
            VStack(spacing: 0) {
                Divider()
                
                VStack(spacing: 12) {
                    // Filter chips (if any)
                    FilterChipSection(filterGroups: filterGroups)
                    
                    // Search bar with add button
                    ContextualSearchBar(
                        searchText: $searchText,
                        placeholder: "Search verses and references...",
                        addButtonAction: { showAddSheet = true },
                        addButtonLabel: "Add Scripture Memory"
                    )
                }
                .padding()
                .background(Color.appWhite)
            }
        }
        .background(Color.appWhite.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .medium))
                            Text("Back")
                        }
                    }
                    .foregroundColor(.appGreenDark)
                }
            }
            
            if memorizationSettings.isSystemEnabled && !isEditing {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(showAllVerses ? "Dashboard" : "View All") {
                            showAllVerses.toggle()
                        }
                        
                        
                        if !filteredEntries.isEmpty {
                            Button("Select") { isEditing = true }
                        }
                    }
                }
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        HStack {
                            let selectedCount = selectedEntries.count
                            if selectedCount > 0 {
                                Button("Actions (\(selectedCount))") {
                                    showBulkActions = true
                                }
                                .foregroundColor(.appGreenDark)
                            }
                            
                            Button("Done") {
                                isEditing = false
                                selectedEntries.removeAll()
                            }
                        }
                    } else {
                        if !filteredEntries.isEmpty {
                            Button("Select") { isEditing = true }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddScriptureMemoryView()
                .environmentObject(memorizationSettings)
                .environmentObject(tagStore)
                .environment(\.modelContext, modelContext)
        }
        .sheet(item: $entryToEdit) { entry in
            AddScriptureMemoryView(entryToEdit: entry)
                .environmentObject(memorizationSettings)
                .environmentObject(tagStore)
                .environment(\.modelContext, modelContext)
        }
        .sheet(isPresented: $showBulkActions) {
            ScriptureBulkActionsSheet(
                selectedCount: selectedEntries.count,
                isPresented: $showBulkActions,
                onAddToBinders: { showBulkBinderPicker = true },
                onDelete: { showDeleteConfirmation = true }
            )
        }
        .sheet(isPresented: $showBulkBinderPicker) {
            BulkBinderPickerSheet(
                selectedItems: .scriptureEntries(Array(selectedEntries)),
                isPresented: $showBulkBinderPicker,
                onComplete: {
                    selectedEntries.removeAll()
                    isEditing = false
                }
            )
            .environmentObject(binderStore)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "Delete \(selectedEntries.count) verses?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                // Delete selected entries
                for entry in selectedEntries {
                    modelContext.delete(entry)
                }
                
                do {
                    try modelContext.save()
                } catch {
                    print("Error deleting entries: \(error)")
                }
                
                selectedEntries.removeAll()
                isEditing = false
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .confirmationDialog(
            "Delete verse?",
            isPresented: $showIndividualDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    modelContext.delete(entry)
                    do {
                        try modelContext.save()
                    } catch {
                        print("Error deleting entry: \(error)")
                    }
                }
                entryToDelete = nil
            }
            
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
        } message: {
            if let entry = entryToDelete {
                Text("This will permanently delete \"\(entry.bibleReference)\".")
            }
        }
        .onAppear {
            // Reset filter state when view appears
        }
    }
    
    
    // MARK: - Dashboard View (System ON, Phase View)
    
    @ViewBuilder
    private var dashboardView: some View {
        VStack(spacing: 0) {
            // Statistics header
            if !filteredEntries.isEmpty {
                statisticsHeaderView
            }
            
            let phases = entriesByPhase
            
            List {
                // Phase 1 Section
                if !phases.phase1.isEmpty {
                    Section(header: phaseHeaderView(phase: .phase1, count: phases.phase1.count)) {
                        ForEach(phases.phase1) { entry in
                            if isEditing {
                                HStack {
                                    Image(systemName: selectedEntries.contains(entry) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedEntries.contains(entry) ? .appGreenDark : .gray)
                                        .font(.title3)
                                    
                                    scriptureRowView(entry: entry, showPhase: false)
                                        .environmentObject(binderStore)
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
                                scriptureRowView(entry: entry, showPhase: false)
                                    .environmentObject(binderStore)
                            }
                        }
                    }
                }
                
                // Phase 2 Section
                if !phases.phase2.isEmpty {
                    Section(header: phaseHeaderView(phase: .phase2, count: phases.phase2.count)) {
                        ForEach(phases.phase2) { entry in
                            if isEditing {
                                HStack {
                                    Image(systemName: selectedEntries.contains(entry) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedEntries.contains(entry) ? .appGreenDark : .gray)
                                        .font(.title3)
                                    
                                    scriptureRowView(entry: entry, showPhase: false)
                                        .environmentObject(binderStore)
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
                                scriptureRowView(entry: entry, showPhase: false)
                                    .environmentObject(binderStore)
                            }
                        }
                    }
                }
                
                // Phase 3 Section
                if !phases.phase3.isEmpty {
                    Section(header: phaseHeaderView(phase: .phase3, count: phases.phase3.count)) {
                        ForEach(phases.phase3) { entry in
                            if isEditing {
                                HStack {
                                    Image(systemName: selectedEntries.contains(entry) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedEntries.contains(entry) ? .appGreenDark : .gray)
                                        .font(.title3)
                                    
                                    scriptureRowView(entry: entry, showPhase: false)
                                        .environmentObject(binderStore)
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
                                scriptureRowView(entry: entry, showPhase: false)
                                    .environmentObject(binderStore)
                            }
                        }
                    }
                }
                
                // Empty state if no verses need completion today
                if phases.phase1.isEmpty && phases.phase2.isEmpty && phases.phase3.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Spacer()
                            
                            if filteredEntries.isEmpty {
                                if !searchText.isEmpty || selectedPhase != nil {
                                    // Filtered empty state
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray.opacity(0.6))
                                    Text("No Results")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text("Try adjusting your search or filters")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    // No verses added yet
                                    Image(systemName: "book.closed")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray.opacity(0.6))
                                    Text("No verses added yet")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text("Tap the + button to add your first verse")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                // All caught up
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.appGreenDark)
                                Text("All caught up!")
                                    .font(.headline)
                                    .foregroundColor(.appGreenDark)
                                Text("No verses need completion today")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("Tap 'View All Verses' to see your complete collection")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 8)
                            }
                            
                            Spacer()
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
    
    // MARK: - Scripture List View (All Verses)
    
    @ViewBuilder
    private var scriptureListView: some View {
        if filteredEntries.isEmpty {
            // Empty state for all verses view
            VStack(spacing: 16) {
                Spacer()
                
                if !searchText.isEmpty || selectedPhase != nil {
                    // Filtered empty state
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.6))
                    Text("No Results")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Try adjusting your search or filters")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    // No verses added yet
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.6))
                    Text("No verses added yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Tap the + button to add your first verse")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .padding(.bottom, 120) // Space for search bar
        } else {
            List {
                ForEach(filteredEntries) { entry in
                    if isEditing {
                        HStack {
                            Image(systemName: selectedEntries.contains(entry) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedEntries.contains(entry) ? .appGreenDark : .gray)
                                .font(.title3)
                            
                            scriptureRowView(entry: entry, showPhase: memorizationSettings.isSystemEnabled)
                                .environmentObject(binderStore)
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
                        scriptureRowView(entry: entry, showPhase: memorizationSettings.isSystemEnabled)
                            .environmentObject(binderStore)
                    }
                }
            }
            .listStyle(.plain)
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
                            .foregroundColor(.appGreen)
                        Text("Phase 1")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("\(stats.phase2Verses)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.appGreen)
                        Text("Phase 2")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("\(stats.phase3Verses)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.appGreen)
                        Text("Phase 3")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(stats.versesNeedingCompletionToday)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appGreenMid)
                        Text("Due Today")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
        ScriptureListRow(
            entry: entry,
            showPhase: showPhase,
            onDelete: { deleteEntry(entry) },
            onEdit: { editEntry(entry) }
        )
    }
    
    // MARK: - Individual Entry Actions
    
    private func deleteEntry(_ entry: ScriptureMemoryEntry) {
        entryToDelete = entry
        showIndividualDeleteConfirmation = true
    }
    
    private func editEntry(_ entry: ScriptureMemoryEntry) {
        entryToEdit = entry
    }
}

// MARK: - Memorization Phase Filter Builder

struct MemorizationPhaseFilterBuilder {
    static func buildPhaseFilters(
        selectedPhase: MemorizationPhase?,
        onPhaseSelected: @escaping (MemorizationPhase?) -> Void
    ) -> FilterGroup {
        let chips: [FilterChipData] = [
            FilterChipData(
                title: "All Phases",
                isSelected: selectedPhase == nil,
                action: { onPhaseSelected(nil) }
            ),
            FilterChipData(
                title: "Phase 1",
                isSelected: selectedPhase == .phase1,
                action: { 
                    if selectedPhase == .phase1 {
                        onPhaseSelected(nil)
                    } else {
                        onPhaseSelected(.phase1)
                    }
                }
            ),
            FilterChipData(
                title: "Phase 2",
                isSelected: selectedPhase == .phase2,
                action: { 
                    if selectedPhase == .phase2 {
                        onPhaseSelected(nil)
                    } else {
                        onPhaseSelected(.phase2)
                    }
                }
            ),
            FilterChipData(
                title: "Phase 3",
                isSelected: selectedPhase == .phase3,
                action: { 
                    if selectedPhase == .phase3 {
                        onPhaseSelected(nil)
                    } else {
                        onPhaseSelected(.phase3)
                    }
                }
            )
        ]
        
        return FilterGroup(chips: chips)
    }
}

// MARK: - Scripture Bulk Actions Sheet

struct ScriptureBulkActionsSheet: View {
    let selectedCount: Int
    @Binding var isPresented: Bool
    
    let onAddToBinders: () -> Void
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
                    
                    Text("\(selectedCount) \(selectedCount == 1 ? "verse" : "verses") selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 0)
            }
            .listRowBackground(Color.appGreenPale.opacity(0.1))
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            
            Section("Actions") {
                Button(action: {
                    onAddToBinders()
                    isPresented = false
                }) {
                    actionRowView(
                        icon: "books.vertical.circle.fill",
                        title: "Add to Binders",
                        subtitle: "Add all selected verses to binders"
                    )
                }
                
                Button(action: {
                    onDelete()
                    isPresented = false
                }) {
                    actionRowView(
                        icon: "trash",
                        title: "Delete",
                        subtitle: "Permanently remove all selected verses",
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

// MARK: - Preview

struct ScriptureMemorizationListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScriptureMemorizationListView()
                .modelContainer(previewContainer)
                .environmentObject(previewTagStore)
                .environmentObject(previewMemorizationSettings)
        }
    }
}
