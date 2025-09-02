//
//  ScriptureMemoryEntry.swift
//  Christian Life Journal
//
//  Fixed version using SwiftData-compatible types only
//

import Foundation
import SwiftData
import CloudKit
import UIKit

@Model
class ScriptureMemoryEntry: Hashable {
    var id: UUID = UUID()
    var bibleReference: String = ""
    var passageText: String = ""
    var dateAdded: Date = Date()
    var isSystemManaged: Bool = false
    
    // Store enum as String instead of custom enum (SwiftData compatible)
    var currentPhaseRaw: String = "phase1"
    
    // Store progress data as simple primitives instead of custom structs
    var phase1DaysCompleted: Int = 0
    var phase1StartDate: Date?
    
    var phase2DaysCompleted: Int = 0
    var phase2StartDate: Date?
    
    var phase3MonthsCompleted: Int = 0
    var phase3StartDate: Date?
    
    var lastCompletionDate: Date?
    var tagIDs: [UUID] = []
    
    // Individual verses support
    var individualVerses: [Int: String] = [:]  // verse number -> verse text
    
    static func == (lhs: ScriptureMemoryEntry, rhs: ScriptureMemoryEntry) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(
        bibleReference: String,
        passageText: String,
        dateAdded: Date = Date(),
        currentPhase: MemorizationPhase = .phase1,
        isSystemManaged: Bool = true
    ) {
        self.id = UUID()
        self.bibleReference = bibleReference
        self.passageText = passageText
        self.dateAdded = dateAdded
        self.currentPhaseRaw = currentPhase.rawValue
        self.isSystemManaged = isSystemManaged
        self.tagIDs = []
    }
    
    // MARK: - Individual Verses Support
    
    /// Returns the display text for flashcards
    var displayText: String {
        if !individualVerses.isEmpty {
            // Generate "16 For God so loved... 17 For God did not send..."
            return individualVerses
                .sorted { $0.key < $1.key }
                .map { "\($0.key) \($0.value)" }
                .joined(separator: " ")
        } else {
            // Fallback to passageText if individualVerses is empty
            return passageText
        }
    }
    
    /// Returns the verse numbers covered by this entry
    var verseNumbers: [Int] {
        return Array(individualVerses.keys).sorted()
    }
    
    
    // MARK: - Computed Properties (maintain compatibility with existing code)
    
    var currentPhase: MemorizationPhase {
        get {
            return MemorizationPhase(rawValue: currentPhaseRaw) ?? .phase1
        }
        set {
            currentPhaseRaw = newValue.rawValue
        }
    }
    
    var phase1Progress: PhaseProgress {
        get {
            var progress = PhaseProgress()
            progress.daysCompleted = phase1DaysCompleted
            progress.startDate = phase1StartDate
            progress.lastCompletionDate = lastCompletionDate
            return progress
        }
        set {
            phase1DaysCompleted = newValue.daysCompleted
            phase1StartDate = newValue.startDate
            if newValue.lastCompletionDate != nil {
                lastCompletionDate = newValue.lastCompletionDate
            }
        }
    }
    
    var phase2Progress: PhaseProgress {
        get {
            var progress = PhaseProgress()
            progress.daysCompleted = phase2DaysCompleted
            progress.startDate = phase2StartDate
            progress.lastCompletionDate = lastCompletionDate
            return progress
        }
        set {
            phase2DaysCompleted = newValue.daysCompleted
            phase2StartDate = newValue.startDate
            if newValue.lastCompletionDate != nil {
                lastCompletionDate = newValue.lastCompletionDate
            }
        }
    }
    
    var phase3Progress: PhaseProgress {
        get {
            var progress = PhaseProgress()
            progress.monthsCompleted = phase3MonthsCompleted
            progress.startDate = phase3StartDate
            progress.lastCompletionDate = lastCompletionDate
            return progress
        }
        set {
            phase3MonthsCompleted = newValue.monthsCompleted
            phase3StartDate = newValue.startDate
            if newValue.lastCompletionDate != nil {
                lastCompletionDate = newValue.lastCompletionDate
            }
        }
    }
    
    // MARK: - Convenience Methods (unchanged from original)
    
    var currentPhaseProgress: PhaseProgress {
        switch currentPhase {
        case .phase1: return phase1Progress
        case .phase2: return phase2Progress
        case .phase3: return phase3Progress
        }
    }
    
    func needsCompletionToday() -> Bool {
        return needsCompletionOn(date: Date())
    }
    
    func needsCompletionOn(date: Date) -> Bool {
        return MemorizationEngine.needsCompletionOn(date: date, entry: self)
    }
    
    func currentDayCompletionText() -> String {
        switch currentPhase {
        case .phase1:
            let day = phase1Progress.daysCompleted + 1
            let repetitions = [25, 20, 15, 10, 5][min(day - 1, 4)]
            return "Complete Day \(day) (\(repetitions) repetitions)"
        case .phase2:
            let day = phase2Progress.daysCompleted + 1
            return "Complete Day \(day) (1 repetition)"
        case .phase3:
            return "Complete Monthly Review (1 repetition)"
        }
    }
    
    func getPhaseIndicators() -> PhaseIndicators {
        var indicators = PhaseIndicators()
        
        let phase1Markers = ["25-", "20-", "15-", "10-", "5"]
        for i in 0..<phase1Progress.daysCompleted {
            indicators.phase1Markers.append(phase1Markers[i])
        }
        
        indicators.phase2TallyCount = phase2Progress.daysCompleted
        indicators.phase3TallyCount = phase3Progress.monthsCompleted
        
        return indicators
    }
    
    func nextCompletionDate() -> Date? {
        let calendar = Calendar.current
        let today = Date()
        
        switch currentPhase {
        case .phase1, .phase2:
            if let lastCompletion = lastCompletionDate,
               calendar.isDate(lastCompletion, inSameDayAs: today) {
                return calendar.date(byAdding: .day, value: 1, to: today)
            }
            return today
            
        case .phase3:
            if let lastCompletion = lastCompletionDate,
               calendar.isDate(lastCompletion, equalTo: today, toGranularity: .month) {
                return calendar.date(byAdding: .month, value: 1, to: today)
            }
            return today
        }
    }
    
    func estimatedPhaseCompletionDate() -> Date? {
        let calendar = Calendar.current
        let today = Date()
        
        switch currentPhase {
        case .phase1:
            let remainingDays = 5 - phase1Progress.daysCompleted
            return calendar.date(byAdding: .day, value: remainingDays, to: today)
            
        case .phase2:
            let remainingDays = 45 - phase2Progress.daysCompleted
            return calendar.date(byAdding: .day, value: remainingDays, to: today)
            
        case .phase3:
            return nil
        }
    }
    
    func isReadyForNextPhase() -> Bool {
        switch currentPhase {
        case .phase1:
            return phase1Progress.isPhaseComplete(for: .phase1)
        case .phase2:
            return phase2Progress.isPhaseComplete(for: .phase2)
        case .phase3:
            return false
        }
    }
    
    func completionStatus() -> CompletionStatus {
        guard isSystemManaged else { return .notManaged }
        
        let calendar = Calendar.current
        let today = Date()
        
        if let lastCompletion = lastCompletionDate,
           calendar.isDate(lastCompletion, inSameDayAs: today) {
            return .completedToday
        }
        
        if needsCompletionOn(date: today) {
            return .dueToday
        }
        
        return .current
    }
}

// MARK: - Supporting Enums (unchanged)

enum CompletionStatus {
    case notManaged
    case dueToday
    case completedToday
    case current
    
    var displayText: String {
        switch self {
        case .notManaged: return ""
        case .dueToday: return "Due"
        case .completedToday: return "Done"
        case .current: return ""
        }
    }
    
    var displayColor: UIColor {
        switch self {
        case .notManaged, .current: return .clear
        case .dueToday: return .systemOrange
        case .completedToday: return .systemGreen
        }
    }
    
    var systemImage: String {
        switch self {
        case .notManaged, .current: return ""
        case .dueToday: return "circle"
        case .completedToday: return "checkmark.circle.fill"
        }
    }
}
