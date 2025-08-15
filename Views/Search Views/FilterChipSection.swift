//
//  FilterChipSection.swift
//  Christian Life Journal
//
//  Created by Claude on 8/15/25.
//

import SwiftUI

// MARK: - Main Filter Chip Section

struct FilterChipSection: View {
    let filterGroups: [FilterGroup]
    
    var body: some View {
        if !filterGroups.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(filterGroups.indices, id: \.self) { groupIndex in
                        let group = filterGroups[groupIndex]
                        
                        // Add divider between groups (except first)
                        if groupIndex > 0 {
                            Divider()
                                .frame(height: 20)
                        }
                        
                        // Filter chips for this group
                        ForEach(group.chips.indices, id: \.self) { chipIndex in
                            let chip = group.chips[chipIndex]
                            FilterChip(
                                title: chip.title,
                                isSelected: chip.isSelected,
                                action: chip.action
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Filter Data Models

struct FilterGroup {
    let chips: [FilterChipData]
}

struct FilterChipData {
    let title: String
    let isSelected: Bool
    let action: () -> Void
}

// MARK: - Tag Filter Builder

struct TagFilterBuilder {
    static func buildTagFilters(
        tags: [Tag],
        selectedTagIDs: Set<UUID>,
        onTagSelected: @escaping (UUID?) -> Void
    ) -> FilterGroup {
        var chips: [FilterChipData] = []
        
        // "All Tags" chip
        chips.append(FilterChipData(
            title: "All Tags",
            isSelected: selectedTagIDs.isEmpty,
            action: { onTagSelected(nil) }
        ))
        
        // Individual tag chips
        for tag in tags.sorted(by: { $0.name < $1.name }) {
            chips.append(FilterChipData(
                title: tag.name,
                isSelected: selectedTagIDs.contains(tag.id),
                action: { 
                    if selectedTagIDs.contains(tag.id) {
                        onTagSelected(nil) // Clear selection
                    } else {
                        onTagSelected(tag.id) // Select this tag
                    }
                }
            ))
        }
        
        return FilterGroup(chips: chips)
    }
}

// MARK: - Speaker Filter Builder

struct SpeakerFilterBuilder {
    static func buildSpeakerFilters(
        speakers: [Speaker],
        selectedSpeaker: String?,
        onSpeakerSelected: @escaping (String?) -> Void
    ) -> FilterGroup {
        var chips: [FilterChipData] = []
        
        // "All Speakers" chip
        chips.append(FilterChipData(
            title: "All Speakers",
            isSelected: selectedSpeaker == nil,
            action: { onSpeakerSelected(nil) }
        ))
        
        // Individual speaker chips
        for speaker in speakers.sorted(by: { $0.name < $1.name }) {
            chips.append(FilterChipData(
                title: speaker.name,
                isSelected: selectedSpeaker == speaker.name,
                action: { 
                    if selectedSpeaker == speaker.name {
                        onSpeakerSelected(nil) // Clear selection
                    } else {
                        onSpeakerSelected(speaker.name) // Select this speaker
                    }
                }
            ))
        }
        
        return FilterGroup(chips: chips)
    }
}

// MARK: - Scripture Filter Builder

struct ScriptureFilterBuilder {
    static func buildScriptureFilters(
        hasScripture: Bool?,
        onScriptureFilterSelected: @escaping (Bool?) -> Void
    ) -> FilterGroup {
        let chips: [FilterChipData] = [
            FilterChipData(
                title: "All Entries",
                isSelected: hasScripture == nil,
                action: { onScriptureFilterSelected(nil) }
            ),
            FilterChipData(
                title: "Has Scripture",
                isSelected: hasScripture == true,
                action: { 
                    if hasScripture == true {
                        onScriptureFilterSelected(nil)
                    } else {
                        onScriptureFilterSelected(true)
                    }
                }
            ),
            FilterChipData(
                title: "No Scripture",
                isSelected: hasScripture == false,
                action: { 
                    if hasScripture == false {
                        onScriptureFilterSelected(nil)
                    } else {
                        onScriptureFilterSelected(false)
                    }
                }
            )
        ]
        
        return FilterGroup(chips: chips)
    }
}

// MARK: - Preview

struct FilterChipSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Tag filters example
            FilterChipSection(
                filterGroups: [
                    TagFilterBuilder.buildTagFilters(
                        tags: [
                            Tag(name: "Worship", type: .user),
                            Tag(name: "Prayer", type: .user),
                            Tag(name: "Faith", type: .user)
                        ],
                        selectedTagIDs: Set([UUID()]),
                        onTagSelected: { _ in }
                    )
                ]
            )
            
            // Multiple filter groups example
            FilterChipSection(
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
                ]
            )
        }
        .padding()
        .background(Color.appWhite)
    }
}