//
//  QuickAddMenuView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/14/25.
//

import SwiftUI

enum QuickAddOption {
    case addTag
    case addSpeaker  
    case addPrayerCategory
    case addBinder
    case addEntry
}

struct QuickAddMenuView: View {
    @Binding var isPresented: Bool
    @Binding var selectedOption: QuickAddOption?
    @Binding var navigationPath: [DashboardNav]
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
                            Text("Quick Add")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.appGreenDark)
                        }
                        
                        Text("Add new content or manage your data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.appGreenPale.opacity(0.1))
                
                Section("Data Management") {
                    Button(action: {
                        selectedOption = .addTag
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.appGreenDark)
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 24, height: 24)
                            
                            Text("Tags")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button(action: {
                        selectedOption = .addSpeaker
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.appGreenDark)
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 24, height: 24)
                            
                            Text("Speakers")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button(action: {
                        selectedOption = .addPrayerCategory
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.appGreenDark)
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 24, height: 24)
                            
                            Text("Prayer Categories")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button(action: {
                        selectedOption = .addBinder
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "books.vertical.fill")
                                .foregroundColor(.appGreenDark)
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 24, height: 24)
                            
                            Text("Binders")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                
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

// MARK: - Preview

struct QuickAddMenuView_Previews: PreviewProvider {
    static var previews: some View {
        QuickAddMenuView(
            isPresented: .constant(true),
            selectedOption: .constant(nil),
            navigationPath: .constant([]),
            presentedSection: .constant(nil)
        )
    }
}
