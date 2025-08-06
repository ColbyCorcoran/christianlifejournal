//
//  ScriptureMemoryEntry.swift
//  Christian Life Journal
//
//  Updated to use MemorizationEngine for completion logic
//

import Foundation
import SwiftData
import UIKit

@Model
class ScriptureMemoryEntry: Hashable {
    @Attribute(.unique) var id: UUID = UUID()
    var bibleReference: String // "John 3:16" or "Romans 8:28-30"
    var passageText: String // Full verse text
    var dateAdded: Date
    var currentPhase: MemorizationPhase
    var isSystemManaged: Bool // true when memorization system is ON
    
    // Phase progress tracking
    var phase1Progress: PhaseProgress
    var phase2Progress: PhaseProgress
    var phase3Progress: PhaseProgress
    
    // Completion tracking
    var lastCompletionDate: Date?
    var tagIDs: [UUID] = [] // Auto-tagged with Bible books + user tags
    
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
        self.currentPhase = currentPhase
        self.isSystemManaged = isSystemManaged
        self.phase1Progress = PhaseProgress()
        self.phase2Progress = PhaseProgress()
        self.phase3Progress = PhaseProgress()
        self.tagIDs = []
    }
    
    // MARK: - Convenience Methods
    
    // Returns the current active phase progress object
    var currentPhaseProgress: PhaseProgress {
        switch currentPhase {
        case .phase1:
            return phase1Progress
        case .phase2:
            return phase2Progress
        case .phase3:
            return phase3Progress
        }
    }
    
    // UPDATED: Uses engine logic for completion check
    func needsCompletionToday() -> Bool {
        return needsCompletionOn(date: Date())
    }
    
    // NEW: Enhanced completion check that works with any date (delegates to engine)
    func needsCompletionOn(date: Date) -> Bool {
        return MemorizationEngine.needsCompletionOn(date: date, entry: self)
    }
    
    // Returns the display text for the current day's completion requirement
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
    
    // Returns visual progress indicators for display on flashcard
    func getPhaseIndicators() -> PhaseIndicators {
        var indicators = PhaseIndicators()
        
        // Phase 1 indicators: "25-", "20-", "15-", "10-", "5"
        let phase1Markers = ["25-", "20-", "15-", "10-", "5"]
        for i in 0..<phase1Progress.daysCompleted {
            indicators.phase1Markers.append(phase1Markers[i])
        }
        
        // Phase 2 indicators: tally marks
        indicators.phase2TallyCount = phase2Progress.daysCompleted
        
        // Phase 3 indicators: tally marks
        indicators.phase3TallyCount = phase3Progress.monthsCompleted
        
        return indicators
    }
    
    // NEW: Gets the next required completion date
    func nextCompletionDate() -> Date? {
        let calendar = Calendar.current
        let today = Date()
        
        switch currentPhase {
        case .phase1, .phase2:
            // Daily completion - next day if already completed today
            if let lastCompletion = lastCompletionDate,
               calendar.isDate(lastCompletion, inSameDayAs: today) {
                return calendar.date(byAdding: .day, value: 1, to: today)
            }
            return today
            
        case .phase3:
            // Monthly completion - next month if already completed this month
            if let lastCompletion = lastCompletionDate,
               calendar.isDate(lastCompletion, equalTo: today, toGranularity: .month) {
                return calendar.date(byAdding: .month, value: 1, to: today)
            }
            return today
        }
    }
    
    // NEW: Gets estimated completion date for current phase
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
            return nil // Ongoing indefinitely
        }
    }
    
    // NEW: Helper to check if verse is ready for next phase
    func isReadyForNextPhase() -> Bool {
        switch currentPhase {
        case .phase1:
            return phase1Progress.isPhaseComplete(for: .phase1)
        case .phase2:
            return phase2Progress.isPhaseComplete(for: .phase2)
        case .phase3:
            return false // Phase 3 never "completes"
        }
    }
    
    // NEW: Gets current completion status for display
    func completionStatus() -> CompletionStatus {
        guard isSystemManaged else { return .notManaged }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Check if completed today
        if let lastCompletion = lastCompletionDate,
           calendar.isDate(lastCompletion, inSameDayAs: today) {
            return .completedToday
        }
        
        // Check if needs completion
        if needsCompletionOn(date: today) {
            return .dueToday
        }
        
        return .current // Up to date but not completed today
    }
}

// MARK: - Supporting Enums

enum CompletionStatus {
    case notManaged      // System is OFF
    case dueToday       // Needs completion today
    case completedToday // Already completed today
    case current        // Up to date, no action needed today
    
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
