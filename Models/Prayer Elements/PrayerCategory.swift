//
//  PrayerCategory.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/11/25.
//

import SwiftUI
import SwiftData
import CloudKit

@Model
class PrayerCategory {
    var id: UUID = UUID()
    var name: String = ""
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

// MARK: - Helper Extensions

extension PrayerCategory {
    static var defaultCategories: [String] {
        return [
            "Personal",
            "Family",
            "Friends", 
            "Ministry",
            "Health",
            "Missions",
            "Community"
        ]
    }
}