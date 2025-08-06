//
//  MemorizationModels.swift
//  Christian Life Journal
//
//  Created by Scripture Memorization System Implementation
//

import Foundation

// MARK: - Memorization Phase Enum

enum MemorizationPhase: String, Codable, CaseIterable {
    case phase1 = "Phase 1"
    case phase2 = "Phase 2"
    case phase3 = "Phase 3"
    
    var description: String {
        switch self {
        case .phase1:
            return "Phase 1 (5 intensive days)"
        case .phase2:
            return "Phase 2 (45 daily reviews)"
        case .phase3:
            return "Phase 3 (monthly reviews)"
        }
    }
    
    var maxDays: Int {
        switch self {
        case .phase1: return 5
        case .phase2: return 45
        case .phase3: return Int.max // Ongoing monthly
        }
    }
}

// MARK: - Phase Progress Tracking

struct PhaseProgress: Codable {
    var daysCompleted: Int = 0
    var monthsCompleted: Int = 0 // Used for Phase 3
    var startDate: Date?
    var lastCompletionDate: Date?
    
    init() {
        self.daysCompleted = 0
        self.monthsCompleted = 0
        self.startDate = nil
        self.lastCompletionDate = nil
    }
    
    init(daysCompleted: Int, monthsCompleted: Int = 0, startDate: Date? = nil) {
        self.daysCompleted = daysCompleted
        self.monthsCompleted = monthsCompleted
        self.startDate = startDate
        self.lastCompletionDate = nil
    }
    
    // Mark a day as completed for this phase
    mutating func markDayCompleted() {
        daysCompleted += 1
        lastCompletionDate = Date()
        if startDate == nil {
            startDate = Date()
        }
    }
    
    // Mark a month as completed (Phase 3 only)
    mutating func markMonthCompleted() {
        monthsCompleted += 1
        lastCompletionDate = Date()
        if startDate == nil {
            startDate = Date()
        }
    }
    
    // Check if this phase is complete
    func isPhaseComplete(for phase: MemorizationPhase) -> Bool {
        switch phase {
        case .phase1:
            return daysCompleted >= 5
        case .phase2:
            return daysCompleted >= 45
        case .phase3:
            return false // Phase 3 never "completes" - ongoing monthly
        }
    }
}

// MARK: - Visual Progress Indicators

struct PhaseIndicators {
    var phase1Markers: [String] = [] // ["25-", "20-", "15-", "10-", "5"]
    var phase2TallyCount: Int = 0
    var phase3TallyCount: Int = 0
    
    init() {}
}

// MARK: - Add Existing Entry Data

struct ExistingEntryData {
    let selectedPhase: MemorizationPhase
    let completedCount: Int
    let hasCompletedToday: Bool
    
    // Calculate the appropriate phase progress based on user input
    func calculatePhaseProgress() -> (MemorizationPhase, PhaseProgress, PhaseProgress, PhaseProgress) {
        var phase1 = PhaseProgress()
        var phase2 = PhaseProgress()
        var phase3 = PhaseProgress()
        var currentPhase = selectedPhase
        
        switch selectedPhase {
        case .phase1:
            phase1.daysCompleted = hasCompletedToday ? completedCount : completedCount
            // If they haven't completed today but said they've done X days,
            // they're ready for day X+1
            
        case .phase2:
            // Phase 1 must be complete to be in Phase 2
            phase1.daysCompleted = 5
            phase2.daysCompleted = hasCompletedToday ? completedCount : completedCount
            
        case .phase3:
            // Both Phase 1 and 2 must be complete
            phase1.daysCompleted = 5
            phase2.daysCompleted = 45
            phase3.monthsCompleted = hasCompletedToday ? completedCount : completedCount
        }
        
        return (currentPhase, phase1, phase2, phase3)
    }
}

// MARK: - System Settings

class MemorizationSettings: ObservableObject {
    @Published var isSystemEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSystemEnabled, forKey: "MemorizationSystemEnabled")
        }
    }
    
    init() {
        // Default to ON as requested
        self.isSystemEnabled = UserDefaults.standard.object(forKey: "MemorizationSystemEnabled") as? Bool ?? true
    }
}
