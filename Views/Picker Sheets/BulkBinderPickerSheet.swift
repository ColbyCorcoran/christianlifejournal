//
//  BulkBinderPickerSheet.swift
//  Christian Life Journal
//
//  Created by Claude on 8/19/25.
//

import SwiftUI
import SwiftData

// MARK: - Bulk Entry Type

enum BulkEntryType {
    case journalEntries([JournalEntry])
    case scriptureEntries([ScriptureMemoryEntry])
    case prayerRequests([PrayerRequest])
    
    var count: Int {
        switch self {
        case .journalEntries(let entries): return entries.count
        case .scriptureEntries(let entries): return entries.count
        case .prayerRequests(let requests): return requests.count
        }
    }
    
    var displayName: String {
        switch self {
        case .journalEntries(let entries): 
            return entries.count == 1 ? "1 entry" : "\(entries.count) entries"
        case .scriptureEntries(let entries): 
            return entries.count == 1 ? "1 verse" : "\(entries.count) verses"
        case .prayerRequests(let requests): 
            return requests.count == 1 ? "1 request" : "\(requests.count) requests"
        }
    }
}

struct BulkBinderPickerSheet: View {
    let selectedItems: BulkEntryType
    @Binding var isPresented: Bool
    let onComplete: () -> Void
    
    @EnvironmentObject var binderStore: BinderStore
    @State private var selectedBinderIDs: Set<UUID> = []
    @State private var searchText: String = ""
    @State private var showSuccessAlert = false
    @State private var successMessage = ""
    
    var filteredBinders: [Binder] {
        if searchText.isEmpty {
            return binderStore.binders.sorted { $0.name < $1.name }
        } else {
            return binderStore.binders.filter { binder in
                binder.name.localizedCaseInsensitiveContains(searchText) ||
                (binder.binderDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }.sorted { $0.name < $1.name }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Custom navigation bar
                HStack {
                    Button("Cancel") {
                        selectedBinderIDs.removeAll()
                        isPresented = false
                    }
                    .foregroundColor(.appGreenDark)
                    
                    Spacer()
                    
                    Text("Add to Binders")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Apply") {
                        addSelectedEntriesToBinders()
                    }
                    .disabled(selectedBinderIDs.isEmpty)
                    .foregroundColor(selectedBinderIDs.isEmpty ? .gray : .appGreenDark)
                }
                .padding()
                
                Divider()
                
                // Search section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Find Binders")
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
                
                // Binders list
                if !filteredBinders.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Available Binders")
                            .font(.headline)
                            .foregroundColor(.appGreenDark)
                            .padding(.horizontal, 20)
                        
                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(filteredBinders, id: \.id) { binder in
                                    binderRowView(binder: binder)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
                } else if !searchText.isEmpty {
                    // No search results
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("No binders found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Try a different search term")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // No binders exist
                    VStack(spacing: 16) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("No Binders Yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Create your first binder from the Binders section")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer()
            }
            .background(Color.appWhite.ignoresSafeArea())
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                isPresented = false
                onComplete()
            }
        } message: {
            Text(successMessage)
        }
    }
    
    @ViewBuilder
    private var searchBarCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16))
            
            TextField("Search binders...", text: $searchText)
                .submitLabel(.search)
                .font(.body)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray.opacity(0.6))
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func binderRowView(binder: Binder) -> some View {
        Button(action: {
            if selectedBinderIDs.contains(binder.id) {
                selectedBinderIDs.remove(binder.id)
            } else {
                selectedBinderIDs.insert(binder.id)
            }
        }) {
            HStack {
                Image(systemName: selectedBinderIDs.contains(binder.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedBinderIDs.contains(binder.id) ? .appGreenDark : .gray)
                    .font(.title3)
                
                // Color strip
                Rectangle()
                    .fill(binder.color)
                    .frame(width: 3, height: 16)
                    .cornerRadius(1.5)
                
                Text(binder.name)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedBinderIDs.contains(binder.id) ? Color.appGreenPale.opacity(0.3) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func addSelectedEntriesToBinders() {
        guard !selectedBinderIDs.isEmpty else { return }
        
        // Add each selected item to each selected binder
        for binderID in selectedBinderIDs {
            switch selectedItems {
            case .journalEntries(let entries):
                for entry in entries {
                    binderStore.addJournalEntry(entry.id, toBinder: binderID)
                }
            case .scriptureEntries(let entries):
                for entry in entries {
                    binderStore.addScriptureEntry(entry.id, toBinder: binderID)
                }
            case .prayerRequests(let requests):
                for request in requests {
                    binderStore.addPrayerRequest(request.id, toBinder: binderID)
                }
            }
        }
        
        // Show success message
        let binderCount = selectedBinderIDs.count
        let binderText = binderCount == 1 ? "binder" : "binders" 
        let itemText = selectedItems.displayName
        
        successMessage = "Added \(itemText) to \(binderCount) \(binderText)"
        showSuccessAlert = true
    }
}

// MARK: - Preview

struct BulkBinderPickerSheet_Previews: PreviewProvider {
    static var previews: some View {
        BulkBinderPickerSheet(
            selectedItems: .journalEntries([]),
            isPresented: .constant(true),
            onComplete: {}
        )
        .environmentObject(previewBinderStore)
    }
}
