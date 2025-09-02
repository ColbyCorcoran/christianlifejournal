//
//  AnalyticsService.swift
//  Christian Life Journal
//
//  Created by Claude on 8/27/25.
//

import Foundation
import SwiftUI

class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    @AppStorage("analyticsEnabled") private var analyticsEnabled = true
    @Published var isEnabled: Bool = true
    
    // PostHog Configuration
    private let apiKey = "phc_u9pPkIrlBfPvyXU3CMiBvMcZR4O02SJ5ITbzRBMwCNl"
    private let hostURL = "https://us.posthog.com"
    private let userID = UUID().uuidString // Anonymous but persistent user ID
    
    private init() {
        self.isEnabled = analyticsEnabled
    }
    
    // MARK: - Public Methods
    
    func setAnalyticsEnabled(_ enabled: Bool) {
        analyticsEnabled = enabled
        isEnabled = enabled
        
        if enabled {
            track("analytics_enabled")
        } else {
            track("analytics_disabled")
        }
    }
    
    /// Send a custom event to PostHog
    func track(_ event: String, properties: [String: Any] = [:]) {
        guard analyticsEnabled else { return }
        
        Task {
            await sendEvent(event: event, properties: properties)
        }
    }
    
    // MARK: - App Lifecycle Events
    
    func trackAppLaunched() {
        track("app_launched", properties: [
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "device_type": UIDevice.current.model,
            "ios_version": UIDevice.current.systemVersion
        ])
    }
    
    func trackDailyActiveUser() {
        // Only track once per day
        let lastTracked = UserDefaults.standard.object(forKey: "last_daily_active") as? Date
        let today = Calendar.current.startOfDay(for: Date())
        
        if lastTracked == nil || !Calendar.current.isDate(lastTracked!, inSameDayAs: today) {
            track("daily_active_user")
            UserDefaults.standard.set(today, forKey: "last_daily_active")
        }
    }
    
    // MARK: - Journal Entry Events
    
    func trackJournalEntryCreated(section: String) {
        track("journal_entry_created", properties: [
            "section": section
        ])
    }
    
    func trackJournalEntryEdited(section: String) {
        track("journal_entry_edited", properties: [
            "section": section
        ])
    }
    
    func trackJournalEntryDeleted(section: String) {
        track("journal_entry_deleted", properties: [
            "section": section
        ])
    }
    
    // MARK: - Scripture Memorization Events
    
    func trackScriptureVerseAdded(systemEnabled: Bool) {
        track("scripture_verse_added", properties: [
            "phase_system_enabled": systemEnabled
        ])
    }
    
    func trackMemorizationSessionCompleted(phase: String, day: Int? = nil) {
        var properties: [String: Any] = ["phase": phase]
        if let day = day {
            properties["day"] = day
        }
        track("memorization_session_completed", properties: properties)
    }
    
    func trackMemorizationPhaseAdvanced(fromPhase: String, toPhase: String) {
        track("memorization_phase_advanced", properties: [
            "from_phase": fromPhase,
            "to_phase": toPhase
        ])
    }
    
    func trackMemorizationSystemToggled(enabled: Bool) {
        track("memorization_system_toggled", properties: [
            "enabled": enabled
        ])
    }
    
    // MARK: - Prayer Events
    
    func trackPrayerRequestCreated() {
        track("prayer_request_created")
    }
    
    func trackPrayerMarkedAnswered(daysSinceCreated: Int) {
        track("prayer_marked_answered", properties: [
            "days_since_created": daysSinceCreated
        ])
    }
    
    // MARK: - Organization Events
    
    func trackBinderCreated(entryCount: Int = 0) {
        track("binder_created", properties: [
            "entry_count": entryCount
        ])
    }
    
    func trackEntriesAddedToBinder(count: Int) {
        track("entries_added_to_binder", properties: [
            "count": count
        ])
    }
    
    func trackBulkActionUsed(action: String, itemCount: Int) {
        track("bulk_action_used", properties: [
            "action": action,
            "item_count": itemCount
        ])
    }
    
    func trackSearchPerformed(section: String) {
        track("search_performed", properties: [
            "section": section
        ])
    }
    
    // MARK: - Settings Events
    
    func trackCloudKitEnabled(deviceType: String = UIDevice.current.model) {
        track("cloudkit_enabled", properties: [
            "device_type": deviceType
        ])
    }
    
    func trackFaceIDEnabled() {
        track("faceid_enabled")
    }
    
    func trackSettingChanged(setting: String, value: Any) {
        track("setting_changed", properties: [
            "setting": setting,
            "value": value
        ])
    }
    
    // MARK: - Navigation Events
    
    func trackSectionViewed(section: String) {
        track("section_viewed", properties: [
            "section": section
        ])
    }
    
    func trackFeatureDiscovered(feature: String) {
        track("feature_discovered", properties: [
            "feature": feature
        ])
    }
    
    // MARK: - Private Methods
    
    private func sendEvent(event: String, properties: [String: Any]) async {
        guard analyticsEnabled else { return }
        
        let url = URL(string: "\(hostURL)/capture/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let eventData: [String: Any] = [
            "api_key": apiKey,
            "event": event,
            "properties": mergeProperties(properties),
            "distinct_id": userID,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "$geoip_disable": true  // Disable automatic location tracking
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: eventData)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                print("PostHog analytics error: HTTP \(httpResponse.statusCode)")
            }
        } catch {
            print("Failed to send analytics event: \(error)")
        }
    }
    
    private func mergeProperties(_ customProperties: [String: Any]) -> [String: Any] {
        var properties = customProperties
        
        // Add standard properties (minimal set for privacy)
        properties["$app_name"] = "Christian Life Journal"
        properties["$app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        properties["$device_type"] = UIDevice.current.model
        properties["$os"] = "iOS"
        properties["$os_version"] = UIDevice.current.systemVersion
        
        // Disable automatic property collection
        properties["$geoip_disable"] = true
        properties["$ip"] = "127.0.0.1"  // Override IP to localhost
        
        return properties
    }
}

// MARK: - Analytics Events Structure

extension AnalyticsService {
    /// Track user retention patterns
    func trackUserRetention() {
        let lastLaunch = UserDefaults.standard.object(forKey: "last_app_launch") as? Date
        let now = Date()
        
        if let lastLaunch = lastLaunch {
            let daysSinceLastLaunch = Calendar.current.dateComponents([.day], from: lastLaunch, to: now).day ?? 0
            
            track("user_returned", properties: [
                "days_since_last_launch": daysSinceLastLaunch
            ])
        }
        
        UserDefaults.standard.set(now, forKey: "last_app_launch")
    }
    
    /// Track feature usage statistics
    func trackFeatureUsageSession() {
        // This could be called periodically to track feature usage patterns
        // Implementation would gather usage stats and send aggregated data
    }
}