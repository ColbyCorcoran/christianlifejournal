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
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var memorizationSettings: MemorizationSettings
    
    // State for filtering and search
    @State private var searchText = ""
    @State private var selectedPhase: MemorizationPhase? = nil
    
    // State for sheets and view modes
    @State private var showAddSheet = false
    @State private var showAllVerses = false
    
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
            // Main content area
            VStack(spacing: 0) {
                // Added view mode toggle header above content
                if memorizationSettings.isSystemEnabled {
                    viewModeToggleHeader
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
                
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
        .navigationTitle("Scripture Memorization")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddSheet) {
            AddScriptureMemoryView()
                .environmentObject(memorizationSettings)
                .environmentObject(tagStore)
                .environment(\.modelContext, modelContext)
        }
        .onAppear {
            // Reset filter state when view appears
        }
    }
    
    // MARK: - View Mode Toggle Header
    
    @ViewBuilder
    private var viewModeToggleHeader: some View {
        HStack {
            Spacer()
            
            Button(showAllVerses ? "Show Dashboard" : "View All Verses") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAllVerses.toggle()
                }
            }
            .font(.subheadline)
            .foregroundColor(.appGreenDark)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.appGreenPale.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appGreenDark.opacity(0.2), lineWidth: 1)
                    )
            )
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
                            if filteredEntries.isEmpty {
                                if !searchText.isEmpty || selectedPhase != nil {
                                    // Filtered empty state
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray)
                                    Text("No Results")
                                        .font(.headline)
                                        .foregroundColor(.appGreenDark)
                                    Text("Try adjusting your search or filters")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    // No verses added yet
                                    Image(systemName: "book.closed")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray)
                                    Text("No verses added yet")
                                        .font(.headline)
                                        .foregroundColor(.appGreenDark)
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
                if !searchText.isEmpty || selectedPhase != nil {
                    // Filtered empty state
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No Results")
                        .font(.headline)
                        .foregroundColor(.appGreenDark)
                    Text("Try adjusting your search or filters")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    // No verses added yet
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No verses added yet")
                        .font(.headline)
                        .foregroundColor(.appGreenDark)
                    Text("Tap the + button to add your first verse")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .padding(.bottom, 120) // Space for search bar
        } else {
            List {
                ForEach(filteredEntries) { entry in
                    scriptureRowView(entry: entry, showPhase: memorizationSettings.isSystemEnabled)
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
            onDelete: { }, // Disable delete in this view
            onEdit: { }    // Disable edit in this view
        )
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