//
//  MemorizationEngine.swift
//  Christian Life Journal
//
//  Enhanced core logic engine for Scripture memorization system
//

import Foundation
import SwiftData

class MemorizationEngine: ObservableObject {
    
    // MARK: - Daily Calculation Methods
    
    // Gets all verses that need completion for a specific date
    static func versesNeedingCompletion(for date: Date, entries: [ScriptureMemoryEntry]) -> [ScriptureMemoryEntry] {
        return entries.filter { entry in
            guard entry.isSystemManaged else { return false }
            return needsCompletionOn(date: date, entry: entry)
        }
    }
    
    // Checks if a specific verse needs completion on a specific date
    static func needsCompletionOn(date: Date, entry: ScriptureMemoryEntry) -> Bool {
        let calendar = Calendar.current
        
        // Check if already completed on this date
        if let lastCompletion = entry.lastCompletionDate,
           calendar.isDate(lastCompletion, inSameDayAs: date) {
            return false
        }
        
        switch entry.currentPhase {
        case .phase1:
            // Phase 1: Complete if haven't finished all 5 days and haven't done today
            return entry.phase1Progress.daysCompleted < 5
            
        case .phase2:
            // Phase 2: Complete if haven't finished all 45 days and haven't done today
            return entry.phase2Progress.daysCompleted < 45
            
        case .phase3:
            // Phase 3: Complete once per month
            if let lastCompletion = entry.lastCompletionDate {
                return !calendar.isDate(lastCompletion, equalTo: date, toGranularity: .month)
            }
            return true
        }
    }
    
    // Gets verses grouped by phase for dashboard display
    static func versesByPhase(entries: [ScriptureMemoryEntry]) -> (phase1: [ScriptureMemoryEntry], phase2: [ScriptureMemoryEntry], phase3: [ScriptureMemoryEntry]) {
        let today = Date()
        let activeEntries = entries.filter { $0.isSystemManaged }
        
        let phase1 = activeEntries.filter {
            $0.currentPhase == .phase1 && needsCompletionOn(date: today, entry: $0)
        }
        
        let phase2 = activeEntries.filter {
            $0.currentPhase == .phase2 && needsCompletionOn(date: today, entry: $0)
        }
        
        let phase3 = activeEntries.filter {
            $0.currentPhase == .phase3 && needsCompletionOn(date: today, entry: $0)
        }
        
        return (phase1, phase2, phase3)
    }
    
    // MARK: - Completion Processing
    
    // Processes completion for a verse and handles phase advancement
    static func processCompletion(for entry: ScriptureMemoryEntry, on date: Date = Date(), modelContext: ModelContext) throws {
        let calendar = Calendar.current
        
        // Prevent duplicate completions on same day
        if let lastCompletion = entry.lastCompletionDate,
           calendar.isDate(lastCompletion, inSameDayAs: date) {
            return
        }
        
        // Process completion based on current phase
        switch entry.currentPhase {
        case .phase1:
            entry.phase1Progress.markDayCompleted()
            entry.lastCompletionDate = date
            
            // Auto-advance to Phase 2 if Phase 1 is complete
            if entry.phase1Progress.isPhaseComplete(for: .phase1) {
                advanceToNextPhase(entry: entry)
            }
            
        case .phase2:
            entry.phase2Progress.markDayCompleted()
            entry.lastCompletionDate = date
            
            // Auto-advance to Phase 3 if Phase 2 is complete
            if entry.phase2Progress.isPhaseComplete(for: .phase2) {
                advanceToNextPhase(entry: entry)
            }
            
        case .phase3:
            entry.phase3Progress.markMonthCompleted()
            entry.lastCompletionDate = date
        }
        
        try modelContext.save()
    }
    
    // Advances a verse to the next phase
    private static func advanceToNextPhase(entry: ScriptureMemoryEntry) {
        switch entry.currentPhase {
        case .phase1:
            entry.currentPhase = .phase2
            // Initialize Phase 2 start date
            if entry.phase2Progress.startDate == nil {
                entry.phase2Progress.startDate = Date()
            }
            
        case .phase2:
            entry.currentPhase = .phase3
            // Initialize Phase 3 start date
            if entry.phase3Progress.startDate == nil {
                entry.phase3Progress.startDate = Date()
            }
            
        case .phase3:
            // Phase 3 doesn't advance further
            break
        }
    }
    
    // MARK: - Adding Existing Verses
    
    // Configures a new entry with existing progress data
    static func configureExistingEntry(
        entry: ScriptureMemoryEntry,
        phase: MemorizationPhase,
        completedCount: Int,
        hasCompletedToday: Bool
    ) {
        let existingData = ExistingEntryData(
            selectedPhase: phase,
            completedCount: completedCount,
            hasCompletedToday: hasCompletedToday
        )
        
        let (currentPhase, phase1, phase2, phase3) = existingData.calculatePhaseProgress()
        
        entry.currentPhase = currentPhase
        entry.phase1Progress = phase1
        entry.phase2Progress = phase2
        entry.phase3Progress = phase3
        
        // Set completion date if they completed today
        if hasCompletedToday {
            entry.lastCompletionDate = Date()
        }
    }
    
    // MARK: - Statistics and Progress
    
    // Gets overall memorization statistics
    static func getStatistics(entries: [ScriptureMemoryEntry]) -> MemorizationStatistics {
        let systemManagedEntries = entries.filter { $0.isSystemManaged }
        
        let phase1Count = systemManagedEntries.filter { $0.currentPhase == .phase1 }.count
        let phase2Count = systemManagedEntries.filter { $0.currentPhase == .phase2 }.count
        let phase3Count = systemManagedEntries.filter { $0.currentPhase == .phase3 }.count
        
        let todayNeeded = versesNeedingCompletion(for: Date(), entries: systemManagedEntries).count
        
        return MemorizationStatistics(
            totalVerses: systemManagedEntries.count,
            phase1Verses: phase1Count,
            phase2Verses: phase2Count,
            phase3Verses: phase3Count,
            versesNeedingCompletionToday: todayNeeded
        )
    }
    
    // MARK: - Streak Tracking
    
    // Calculates current completion streak
    static func calculateCompletionStreak(entries: [ScriptureMemoryEntry]) -> Int {
        let calendar = Calendar.current
        var currentDate = Date()
        var streakDays = 0
        
        // Go backwards day by day until we find a day with no completions
        while streakDays < 365 { // Max 1 year lookback
            let versesForDay = versesNeedingCompletion(for: currentDate, entries: entries)
            let completedForDay = entries.filter { entry in
                guard let lastCompletion = entry.lastCompletionDate else { return false }
                return calendar.isDate(lastCompletion, inSameDayAs: currentDate)
            }
            
            // If there were verses needed but none completed, streak ends
            if !versesForDay.isEmpty && completedForDay.isEmpty {
                break
            }
            
            // If there were verses needed and all were completed, continue streak
            if !versesForDay.isEmpty && completedForDay.count >= versesForDay.count {
                streakDays += 1
            }
            
            // Move to previous day
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streakDays
    }
}

// MARK: - Supporting Types

struct MemorizationStatistics {
    let totalVerses: Int
    let phase1Verses: Int
    let phase2Verses: Int
    let phase3Verses: Int
    let versesNeedingCompletionToday: Int
    
    var completionRate: Double {
        guard totalVerses > 0 else { return 0 }
        let completed = totalVerses - versesNeedingCompletionToday
        return Double(completed) / Double(totalVerses)
    }
}

// MARK: - Validation Helpers

extension MemorizationEngine {
    
    // Validates and fixes any inconsistent verse states
    static func validateAndFixVerses(entries: [ScriptureMemoryEntry], modelContext: ModelContext) throws {
        for entry in entries where entry.isSystemManaged {
            var needsSave = false
            
            // Fix phase mismatches
            if entry.currentPhase == .phase2 && entry.phase1Progress.daysCompleted < 5 {
                entry.currentPhase = .phase1
                needsSave = true
            }
            
            if entry.currentPhase == .phase3 && (entry.phase1Progress.daysCompleted < 5 || entry.phase2Progress.daysCompleted < 45) {
                if entry.phase1Progress.daysCompleted < 5 {
                    entry.currentPhase = .phase1
                } else if entry.phase2Progress.daysCompleted < 45 {
                    entry.currentPhase = .phase2
                }
                needsSave = true
            }
            
            // Fix missing start dates
            if entry.phase1Progress.daysCompleted > 0 && entry.phase1Progress.startDate == nil {
                entry.phase1Progress.startDate = entry.dateAdded
                needsSave = true
            }
            
            if needsSave {
                try modelContext.save()
            }
        }
    }
}
