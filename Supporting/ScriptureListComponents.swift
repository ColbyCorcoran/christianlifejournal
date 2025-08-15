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