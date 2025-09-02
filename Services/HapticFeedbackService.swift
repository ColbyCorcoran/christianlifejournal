//
//  HapticFeedbackService.swift
//  Christian Life Journal
//
//  Created by Claude on 8/27/25.
//

import Foundation
import UIKit
import SwiftUI

class HapticFeedbackService: ObservableObject {
    static let shared = HapticFeedbackService()
    
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    private init() {
        // Prepare generators for better responsiveness
        prepareGenerators()
    }
    
    // MARK: - Public Methods
    
    /// Call when user successfully completes an action (save, complete task, etc.)
    func success() {
        guard hapticFeedbackEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Call when user encounters a warning or needs attention
    func warning() {
        guard hapticFeedbackEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
    }
    
    /// Call when an error occurs
    func error() {
        guard hapticFeedbackEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }
    
    /// Call when user makes selections (toggles, picks items, etc.)
    func selection() {
        guard hapticFeedbackEnabled else { return }
        selectionGenerator.selectionChanged()
    }
    
    /// Subtle haptic for minor interactions
    func lightImpact() {
        guard hapticFeedbackEnabled else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    /// Medium haptic for important state changes
    func mediumImpact() {
        guard hapticFeedbackEnabled else { return }
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Strong haptic for major actions
    func heavyImpact() {
        guard hapticFeedbackEnabled else { return }
        heavyImpactGenerator.impactOccurred()
    }
    
    // MARK: - Semantic Haptic Methods
    
    /// Journal entry saved successfully
    func journalEntrySaved() {
        success()
    }
    
    /// Journal entry deleted
    func journalEntryDeleted() {
        mediumImpact()
    }
    
    /// Scripture memorization session completed
    func scriptureSessionCompleted() {
        success()
    }
    
    /// Scripture memorization phase progressed
    func scripturePhaseProgressed() {
        mediumImpact()
    }
    
    /// Prayer marked as answered
    func prayerAnswered() {
        success()
    }
    
    /// Authentication successful
    func authenticationSuccess() {
        success()
    }
    
    /// Authentication failed
    func authenticationFailed() {
        error()
    }
    
    /// CloudKit sync completed
    func syncCompleted() {
        lightImpact()
    }
    
    /// CloudKit sync failed
    func syncFailed() {
        warning()
    }
    
    /// Bulk selection changed
    func bulkSelectionChanged() {
        selection()
    }
    
    /// Toggle switch changed
    func toggleChanged() {
        selection()
    }
    
    /// Filter applied
    func filterApplied() {
        lightImpact()
    }
    
    /// Important setting changed
    func importantSettingChanged() {
        mediumImpact()
    }
    
    /// Button pressed (for primary actions)
    func buttonPressed() {
        lightImpact()
    }
    
    /// Long press detected
    func longPress() {
        mediumImpact()
    }
    
    // MARK: - Private Methods
    
    private func prepareGenerators() {
        selectionGenerator.prepare()
        notificationGenerator.prepare()
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
    }
    
    // MARK: - Settings
    
    var isEnabled: Bool {
        get { hapticFeedbackEnabled }
        set { 
            hapticFeedbackEnabled = newValue
            if newValue {
                prepareGenerators()
            }
        }
    }
    
    /// Test haptic for settings preview
    func testHaptic() {
        guard hapticFeedbackEnabled else { return }
        // Play a sequence of different haptics for demo
        selection()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.success()
            }
        }
    }
}