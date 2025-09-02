//
//  PrayerRequest.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/11/25.
//

import SwiftUI
import SwiftData
import CloudKit

@Model
class PrayerRequest {
    var id: UUID = UUID()
    var title: String = ""
    var requestDescription: String = ""
    var dateAdded: Date = Date()
    var isAnswered: Bool = false
    var dateAnswered: Date?
    var answerNotes: String?
    var tagIDs: [UUID] = []
    var categoryIDs: [UUID] = []
    var scripture: String? // Added scripture passages support
    
    init(title: String = "", requestDescription: String = "", dateAdded: Date = Date(), isAnswered: Bool = false, dateAnswered: Date? = nil, answerNotes: String? = nil, tagIDs: [UUID] = [], categoryIDs: [UUID] = [], scripture: String? = nil) {
        self.id = UUID()
        self.title = title
        self.requestDescription = requestDescription
        self.dateAdded = dateAdded
        self.isAnswered = isAnswered
        self.dateAnswered = dateAnswered
        self.answerNotes = answerNotes
        self.tagIDs = tagIDs
        self.categoryIDs = categoryIDs
        self.scripture = scripture
    }
}

// MARK: - Helper Extensions

extension PrayerRequest {
    var daysSincePrayed: Int {
        Calendar.current.dateComponents([.day], from: dateAdded, to: Date()).day ?? 0
    }
    
    var daysPrayedFor: Int? {
        guard let answerDate = dateAnswered else { return nil }
        return Calendar.current.dateComponents([.day], from: dateAdded, to: answerDate).day ?? 0
    }
    
    var formattedDateAdded: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dateAdded)
    }
    
    var formattedDateAnswered: String? {
        guard let date = dateAnswered else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}