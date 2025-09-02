//
//  Tag.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/7/25.
//

import Foundation
import SwiftData

enum TagType: String, Codable, CaseIterable {
    case `default`
    case user
}

@Model
class Tag {
    var id: UUID = UUID()
    var name: String = ""
    var typeRaw: String = "user" // Store enum as string for SwiftData compatibility
    
    // Computed property for type
    var type: TagType {
        get { TagType(rawValue: typeRaw) ?? .user }
        set { typeRaw = newValue.rawValue }
    }
    
    init(name: String, type: TagType) {
        self.id = UUID()
        self.name = name
        self.typeRaw = type.rawValue
    }
    
    // Required for SwiftData
    init() {
        self.id = UUID()
        self.name = ""
        self.typeRaw = TagType.user.rawValue
    }
    
    // MARK: - Preview Mock Creation
    static func previewTag(name: String, type: TagType) -> Tag {
        let tag = Tag()
        tag.name = name
        tag.type = type
        return tag
    }
}
