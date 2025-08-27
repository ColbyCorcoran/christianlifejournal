//
//  ScriptureListComponents.swift
//  Christian Life Journal
//
//  Extracted reusable components for scripture list views
//

import SwiftUI
import SwiftData

// MARK: - Scripture List Row

struct ScriptureListRow: View {
    let entry: ScriptureMemoryEntry
    let showPhase: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void
    @EnvironmentObject var binderStore: BinderStore

    var body: some View {
        NavigationLink(value: DashboardNav.scriptureEntry(entry.id)) {
            HStack(spacing: 0) {
                // Binder color strips (vertical tabs)
                let entryBinders = binderStore.bindersContaining(scriptureEntryID: entry.id)
                if !entryBinders.isEmpty {
                    VStack(spacing: 2) {
                        ForEach(Array(entryBinders.prefix(3)), id: \.id) { binder in
                            Rectangle()
                                .fill(binder.color)
                                .frame(width: 4)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.trailing, 8)
                }
                
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
                        
                        // Binders now shown as vertical color strips on the left
                    }
                }
                
                Spacer()
                
                // Completion indicator using engine logic
                CompletionStatusView(entry: entry)
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

// MARK: - Completion Status Component

struct CompletionStatusView: View {
    let entry: ScriptureMemoryEntry
    
    var body: some View {
        // Only show completion status if system is managed
        if entry.isSystemManaged {
            let needsCompletion = entry.needsCompletionOn(date: Date())
            let calendar = Calendar.current
            let hasCompletedToday = entry.lastCompletionDate.map {
                calendar.isDate($0, inSameDayAs: Date())
            } ?? false
            
            if needsCompletion {
                VStack {
                    Image(systemName: "circle")
                        .foregroundColor(.appGreenMid)
                        .font(.caption)
                    Text("Due")
                        .font(.caption2)
                        .foregroundColor(.appGreenMid)
                }
            } else if hasCompletedToday {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appGreenDark)
                        .font(.caption)
                    Text("Done")
                        .font(.caption2)
                        .foregroundColor(.appGreenDark)
                }
            }
        }
    }
}