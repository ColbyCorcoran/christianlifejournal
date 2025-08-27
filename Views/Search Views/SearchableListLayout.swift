//
//  SearchableListLayout.swift
//  Christian Life Journal
//
//  Created by Claude on 8/15/25.
//

import SwiftUI

struct SearchableListLayout<Content: View>: View {
    let content: Content
    let filterGroups: [FilterGroup]
    @Binding var searchText: String
    let searchPlaceholder: String
    let addButtonAction: () -> Void
    let addButtonLabel: String
    let navigationTitle: String
    
    init(
        navigationTitle: String,
        searchText: Binding<String>,
        searchPlaceholder: String,
        filterGroups: [FilterGroup] = [],
        addButtonAction: @escaping () -> Void,
        addButtonLabel: String,
        @ViewBuilder content: () -> Content
    ) {
        self.navigationTitle = navigationTitle
        self._searchText = searchText
        self.searchPlaceholder = searchPlaceholder
        self.filterGroups = filterGroups
        self.addButtonAction = addButtonAction
        self.addButtonLabel = addButtonLabel
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Content area
            content
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
                        placeholder: searchPlaceholder,
                        addButtonAction: addButtonAction,
                        addButtonLabel: addButtonLabel
                    )
                }
                .padding()
                .background(Color.appWhite)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Empty State Component

struct SearchableEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String?
    let searchText: String
    let addButtonAction: (() -> Void)?
    let addButtonTitle: String?
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        searchText: String = "",
        addButtonAction: (() -> Void)? = nil,
        addButtonTitle: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.searchText = searchText
        self.addButtonAction = addButtonAction
        self.addButtonTitle = addButtonTitle
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: searchText.isEmpty ? icon : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.6))
            
            Text(searchText.isEmpty ? title : "No Results")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Only show subtitle if it exists and is not empty
            if searchText.isEmpty {
                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            } else {
                Text("Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Show add button only if no search and action provided
            if searchText.isEmpty, 
               let action = addButtonAction,
               let buttonTitle = addButtonTitle {
                Button(buttonTitle) {
                    action()
                }
                .foregroundColor(.appGreenDark)
                .font(.headline)
                .padding(.top)
            }
            
            Spacer()
        }
    }
}

// MARK: - Entry Row Component

struct JournalEntryRow: View {
    let entry: JournalEntry
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var binderStore: BinderStore
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Binder color strips (vertical tabs)
            let entryBinders = binderStore.bindersContaining(journalEntryID: entry.id)
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
            
            HStack(alignment: .top, spacing: 12) {
                // Section Icon
                Image(systemName: JournalSection(rawValue: entry.section)?.entryIconName ?? "doc.fill")
                    .font(.title3)
                    .foregroundColor(.appGreenDark)
                    .frame(width: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title and Date
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title.isEmpty ? formattedDate(entry.date) : entry.title)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        if let bodyText = entry.bodyText, !bodyText.isEmpty {
                            Text(bodyText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        if entry.title.isEmpty {
                            Text(entry.section)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.appGreenDark)
                        } else {
                            Text(formattedDate(entry.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(entry.section)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.appGreenDark)
                        }
                        
                    }
                }
                
                // Tags and Speaker (binders now shown as vertical strips)
                let hasSpeaker = (entry.section == "Sermon Notes" || entry.section == "Group Notes") && !(entry.speaker?.isEmpty ?? true)
                let hasTags = !entry.tagIDs.isEmpty
                
                if hasSpeaker || hasTags {
                    HStack {
                        // Speaker chip (for sermon notes and group notes)
                        if hasSpeaker, let speaker = entry.speaker {
                            Text(speaker)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.appGreenLight.opacity(0.4))
                                )
                                .foregroundColor(.appGreenDark)
                        }
                        
                        // Tag chips (now with more space since binders are vertical strips)
                        if hasTags {
                            let userTags = entry.tagIDs.prefix(hasSpeaker ? 3 : 4).compactMap { tagID in
                                tagStore.userTags.first { $0.id == tagID }
                            }
                            
                            ForEach(userTags, id: \.id) { tag in
                                Text(tag.name)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.appGreenMedium.opacity(0.3))
                                    )
                                    .foregroundColor(.appGreenDark)
                            }
                            
                            let maxTags = hasSpeaker ? 3 : 4
                            if entry.tagIDs.count > maxTags {
                                Text("+\(entry.tagIDs.count - maxTags)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
        )
    }
}

// MARK: - Preview

struct SearchableListLayout_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchableListLayout(
                navigationTitle: "Personal Time with God",
                searchText: .constant(""),
                searchPlaceholder: "Search personal time entries...",
                filterGroups: [
                    TagFilterBuilder.buildTagFilters(
                        tags: [Tag(name: "Worship", type: .user)],
                        selectedTagIDs: Set(),
                        onTagSelected: { _ in }
                    ),
                    ScriptureFilterBuilder.buildScriptureFilters(
                        hasScripture: nil,
                        onScriptureFilterSelected: { _ in }
                    )
                ],
                addButtonAction: {},
                addButtonLabel: "Add Personal Time Entry"
            ) {
                SearchableEmptyState(
                    icon: "person.circle",
                    title: "No Personal Time Entries",
                    subtitle: "Record personal devotions and reflections",
                    addButtonAction: {},
                    addButtonTitle: "Add Personal Time Entry"
                )
            }
        }
    }
}
