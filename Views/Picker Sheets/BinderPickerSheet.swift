//
//  BinderPickerSheet.swift
//  Christian Life Journal
//
//  Picker sheet for adding/removing entries from binders
//

import SwiftUI

struct BinderPickerSheet: View {
    // Properties for detail view mode (existing entries)
    let entryType: BinderEntryType?
    let entryID: UUID?
    let entryTitle: String?
    
    // Property for add entry mode (binding)
    @Binding private var bindingSelectedBinderIDs: Set<UUID>
    private let useBinding: Bool
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var binderStore: BinderStore
    
    @State private var searchText = ""
    @State private var internalSelectedBinderIDs: Set<UUID> = []
    @State private var temporarySelectedBinderIDs: Set<UUID> = []
    
    // Computed property to use either temporary (binding mode) or internal (detail mode) state
    private var selectedBinderIDs: Set<UUID> {
        get {
            useBinding ? temporarySelectedBinderIDs : internalSelectedBinderIDs
        }
        nonmutating set {
            if useBinding {
                temporarySelectedBinderIDs = newValue
            } else {
                internalSelectedBinderIDs = newValue
            }
        }
    }
    
    // Initializer for detail view mode (existing entries)
    init(entryType: BinderEntryType, entryID: UUID, entryTitle: String) {
        self.entryType = entryType
        self.entryID = entryID
        self.entryTitle = entryTitle
        self.useBinding = false
        self._bindingSelectedBinderIDs = .constant([])
    }
    
    // Initializer for add entry mode (binding)
    init(selectedBinderIDs: Binding<Set<UUID>>) {
        self.entryType = nil
        self.entryID = nil
        self.entryTitle = nil
        self.useBinding = true
        self._bindingSelectedBinderIDs = selectedBinderIDs
    }
    
    private var filteredBinders: [Binder] {
        let allBinders = binderStore.binders.filter { !$0.isArchived }
        if searchText.isEmpty {
            return allBinders.sorted { $0.name < $1.name }
        } else {
            return allBinders
                .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.name < $1.name }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appWhite.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search section
                    searchSection
                    
                    // Binders list
                    if !filteredBinders.isEmpty {
                        bindersListSection
                    } else if !searchText.isEmpty {
                        noSearchResultsView
                    } else {
                        emptyStateView
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle(useBinding ? "Select Binders" : "Add to Binders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.appGreenDark)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        if useBinding {
                            bindingSelectedBinderIDs = temporarySelectedBinderIDs
                            dismiss()
                        } else {
                            saveChanges() // Detail view mode - save changes to binders
                        }
                    }
                    .foregroundColor(.appGreenDark)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if useBinding {
                    // Initialize temporary selection with current binding value
                    temporarySelectedBinderIDs = bindingSelectedBinderIDs
                } else {
                    // Load current binder membership for detail view mode
                    loadCurrentBinderMembership()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Binders")
                .font(.headline)
                .foregroundColor(.appGreenDark)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search binders...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.appGreenDark.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.appGreenPale.opacity(0.1))
                    )
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var bindersListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader
            bindersScrollView
        }
        .padding(.top, 20)
    }
    
    private var sectionHeader: some View {
        Text("Available Binders")
            .font(.headline)
            .foregroundColor(.appGreenDark)
            .padding(.horizontal, 20)
    }
    
    private var bindersScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(filteredBinders, id: \.id) { binder in
                    binderRowView(for: binder)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func binderRowView(for binder: Binder) -> some View {
        let isSelected = selectedBinderIDs.contains(binder.id)
        
        return Button(action: { toggleBinder(binder) }) {
            HStack {
                selectionIcon(isSelected: isSelected)
                binderColorStrip(for: binder)
                binderInfo(for: binder)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(binderRowBackground(isSelected: isSelected))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func selectionIcon(isSelected: Bool) -> some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .foregroundColor(isSelected ? .appGreenDark : .gray)
            .font(.title3)
    }
    
    private func binderColorStrip(for binder: Binder) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(hex: binder.colorHex))
            .frame(width: 4, height: 32)
    }
    
    private func binderInfo(for binder: Binder) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(binder.name)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            if let description = binder.binderDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
    
    private func binderRowBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isSelected ? Color.appGreenPale.opacity(0.3) : Color.clear)
    }
    
    private var noSearchResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No binders found")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Try a different search term")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No binders yet")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Create your first binder to start organizing entries")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func toggleBinder(_ binder: Binder) {
        if selectedBinderIDs.contains(binder.id) {
            selectedBinderIDs.remove(binder.id)
        } else {
            selectedBinderIDs.insert(binder.id)
        }
    }
    
    private func loadCurrentBinderMembership() {
        // Load which binders currently contain this entry (detail view mode only)
        guard let entryType = entryType, let entryID = entryID else { return }
        
        switch entryType {
        case .journalEntry:
            selectedBinderIDs = Set(binderStore.bindersContaining(journalEntryID: entryID).map { $0.id })
        case .scriptureEntry:
            selectedBinderIDs = Set(binderStore.bindersContaining(scriptureEntryID: entryID).map { $0.id })
        case .prayerRequest:
            selectedBinderIDs = Set(binderStore.bindersContaining(prayerRequestID: entryID).map { $0.id })
        }
    }
    
    private func saveChanges() {
        // Save changes (detail view mode only)
        guard let entryType = entryType, let entryID = entryID else { return }
        
        // Get current and new binder memberships
        let currentBinders: Set<UUID>
        switch entryType {
        case .journalEntry:
            currentBinders = Set(binderStore.bindersContaining(journalEntryID: entryID).map { $0.id })
        case .scriptureEntry:
            currentBinders = Set(binderStore.bindersContaining(scriptureEntryID: entryID).map { $0.id })
        case .prayerRequest:
            currentBinders = Set(binderStore.bindersContaining(prayerRequestID: entryID).map { $0.id })
        }
        
        // Add to new binders
        let bindersToAdd = selectedBinderIDs.subtracting(currentBinders)
        for binderID in bindersToAdd {
            switch entryType {
            case .journalEntry:
                binderStore.addJournalEntry(entryID, toBinder: binderID)
            case .scriptureEntry:
                binderStore.addScriptureEntry(entryID, toBinder: binderID)
            case .prayerRequest:
                binderStore.addPrayerRequest(entryID, toBinder: binderID)
            }
        }
        
        // Remove from old binders
        let bindersToRemove = currentBinders.subtracting(selectedBinderIDs)
        for binderID in bindersToRemove {
            switch entryType {
            case .journalEntry:
                binderStore.removeJournalEntry(entryID, fromBinder: binderID)
            case .scriptureEntry:
                binderStore.removeScriptureEntry(entryID, fromBinder: binderID)
            case .prayerRequest:
                binderStore.removePrayerRequest(entryID, fromBinder: binderID)
            }
        }
        
        dismiss()
    }
}

// MARK: - Supporting Types

enum BinderEntryType {
    case journalEntry
    case scriptureEntry
    case prayerRequest
}


// MARK: - Preview

struct BinderPickerSheet_Previews: PreviewProvider {
    static var previews: some View {
        // Preview for detail view mode
        BinderPickerSheet(
            entryType: .journalEntry,
            entryID: UUID(),
            entryTitle: "Sample Entry"
        )
        .environmentObject(BinderStore.previewStore(modelContext: previewContainer.mainContext))
        .modelContainer(previewContainer)
        .previewDisplayName("Detail View Mode")
        
        // Preview for add entry mode  
        BinderPickerSheet(selectedBinderIDs: .constant([]))
            .environmentObject(BinderStore.previewStore(modelContext: previewContainer.mainContext))
            .modelContainer(previewContainer)
            .previewDisplayName("Add Entry Mode")
    }
}
