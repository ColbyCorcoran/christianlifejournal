//
//  TagStore.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/30/25.
//

import SwiftUI

enum TagType: String, Codable, Equatable {
    case `default`
    case user
}

struct Tag: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
    let type: TagType

    init(name: String, type: TagType) {
        self.id = UUID()
        self.name = name
        self.type = type
    }
}

class TagStore: ObservableObject {
    @Published var tags: [Tag] = []

    // MARK: - Initialization

    init() {
        // Add default tags for Bible books and sections if not already present
        if tags.isEmpty {
            tags = TagStore.defaultBibleBookTags + TagStore.defaultSectionTags
        }
    }

    // MARK: - Default Tags

    static var defaultBibleBookTags: [Tag] {
        bibleBooks.map { Tag(name: $0.name, type: .default) }
    }

    static var defaultSectionTags: [Tag] {
        JournalSection.allCases.map { Tag(name: $0.displayName, type: .default) }
    }

    // MARK: - Tag Management

    func addUserTag(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              !tags.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        tags.append(Tag(name: trimmed, type: .user))
    }

    func removeUserTag(at index: Int) {
        guard tags.indices.contains(index), tags[index].type == .user else { return }
        tags.remove(at: index)
    }

    func updateUserTag(at index: Int, with name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard tags.indices.contains(index), tags[index].type == .user, !trimmed.isEmpty else { return }
        tags[index] = Tag(name: trimmed, type: .user)
    }

    // MARK: - Tag Queries

    var userTags: [Tag] {
        tags.filter { $0.type == .user }
    }

    var defaultTags: [Tag] {
        tags.filter { $0.type == .default }
    }
    
    func tag(for id: UUID) -> Tag? {
            tags.first { $0.id == id }
        }

    func tag(for name: String) -> Tag? {
        tags.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    func isDefaultTag(_ name: String) -> Bool {
        tag(for: name)?.type == .default
    }
}

