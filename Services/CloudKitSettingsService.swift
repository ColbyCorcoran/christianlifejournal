//
//  CloudKitSettingsService.swift
//  Christian Life Journal
//
//  Created by Claude on 8/29/25.
//  Syncs app settings across devices using CloudKit key-value store
//

import Foundation
import CloudKit
import Combine

class CloudKitSettingsService: ObservableObject {
    static let shared = CloudKitSettingsService()
    
    private let keyValueStore = NSUbiquitousKeyValueStore()
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Settings Properties
    
    @Published var scriptureAutoFillEnabled: Bool = true {
        didSet { syncSetting(key: "scriptureAutoFillEnabled", value: scriptureAutoFillEnabled) }
    }
    
    @Published var selectedTranslation: BibleTranslation = .kjv {
        didSet { syncSetting(key: "selectedTranslation", value: selectedTranslation.rawValue) }
    }
    
    @Published var memorizationSystemEnabled: Bool = true {
        didSet { syncSetting(key: "memorizationSystemEnabled", value: memorizationSystemEnabled) }
    }
    
    @Published var hapticFeedbackEnabled: Bool = true {
        didSet { syncSetting(key: "hapticFeedbackEnabled", value: hapticFeedbackEnabled) }
    }
    
    @Published var analyticsEnabled: Bool = true {
        didSet { syncSetting(key: "analyticsEnabled", value: analyticsEnabled) }
    }
    
    @Published var faceIdEnabled: Bool = false {
        didSet { syncSetting(key: "faceIdEnabled", value: faceIdEnabled) }
    }
    
    @Published var cloudKitEnabled: Bool = false {
        didSet { syncSetting(key: "cloudKitEnabled", value: cloudKitEnabled) }
    }
    
    private init() {
        setupInitialValues()
        setupCloudKitObserver()
    }
    
    // MARK: - Setup Methods
    
    private func setupInitialValues() {
        // Load from CloudKit first, then fallback to UserDefaults for backwards compatibility
        scriptureAutoFillEnabled = getBoolValue(key: "scriptureAutoFillEnabled", fallback: userDefaults.object(forKey: "scriptureAutoFillEnabled") as? Bool ?? true)
        
        let translationString = getStringValue(key: "selectedTranslation", fallback: userDefaults.string(forKey: "scriptureAutoFillTranslation")) ?? BibleTranslation.kjv.rawValue
        selectedTranslation = BibleTranslation(rawValue: translationString) ?? .kjv
        
        memorizationSystemEnabled = getBoolValue(key: "memorizationSystemEnabled", fallback: userDefaults.object(forKey: "memorizationSystemEnabled") as? Bool ?? true)
        hapticFeedbackEnabled = getBoolValue(key: "hapticFeedbackEnabled", fallback: userDefaults.bool(forKey: "hapticFeedbackEnabled"))
        analyticsEnabled = getBoolValue(key: "analyticsEnabled", fallback: userDefaults.bool(forKey: "analyticsEnabled"))
        faceIdEnabled = getBoolValue(key: "faceIdEnabled", fallback: userDefaults.bool(forKey: "faceIdEnabled"))
        cloudKitEnabled = getBoolValue(key: "cloudKitEnabled", fallback: userDefaults.bool(forKey: "cloudKitEnabled"))
        
        // Migrate old UserDefaults values to CloudKit if they exist
        migrateUserDefaultsToCloudKit()
    }
    
    private func setupCloudKitObserver() {
        // Listen for remote changes from other devices
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .sink { [weak self] notification in
                DispatchQueue.main.async {
                    self?.handleRemoteChanges(notification)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - CloudKit Sync Methods
    
    private func syncSetting<T>(key: String, value: T) {
        // Always update local UserDefaults for backwards compatibility and immediate access
        userDefaults.set(value, forKey: key)
        
        // Only sync to CloudKit if CloudKit is enabled
        guard cloudKitEnabled else { return }
        
        // Update CloudKit key-value store
        keyValueStore.set(value, forKey: key)
        keyValueStore.synchronize()
        
        print("🔄 Synced setting '\(key)' = '\(value)' to CloudKit")
    }
    
    private func getBoolValue(key: String, fallback: Bool? = nil) -> Bool {
        if cloudKitEnabled, keyValueStore.object(forKey: key) != nil {
            return keyValueStore.bool(forKey: key)
        }
        return fallback ?? false
    }
    
    private func getStringValue(key: String, fallback: String? = nil) -> String? {
        if cloudKitEnabled, let cloudValue = keyValueStore.string(forKey: key) {
            return cloudValue
        }
        return fallback
    }
    
    private func handleRemoteChanges(_ notification: Notification) {
        guard cloudKitEnabled else { return }
        
        guard let userInfo = notification.userInfo,
              let changeReason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber else {
            return
        }
        
        // Handle different types of changes
        switch changeReason.intValue {
        case NSUbiquitousKeyValueStoreServerChange:
            print("📡 Received settings changes from iCloud")
            updateFromRemote()
        case NSUbiquitousKeyValueStoreInitialSyncChange:
            print("📡 Initial iCloud settings sync complete")
            updateFromRemote()
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            print("⚠️ iCloud key-value store quota exceeded")
        case NSUbiquitousKeyValueStoreAccountChange:
            print("📡 iCloud account changed")
        default:
            break
        }
    }
    
    private func updateFromRemote() {
        // Update published properties from CloudKit values
        let newScriptureAutoFillEnabled = keyValueStore.bool(forKey: "scriptureAutoFillEnabled")
        let newTranslationString = keyValueStore.string(forKey: "selectedTranslation") ?? BibleTranslation.kjv.rawValue
        let newMemorizationSystemEnabled = keyValueStore.bool(forKey: "memorizationSystemEnabled")
        let newHapticFeedbackEnabled = keyValueStore.bool(forKey: "hapticFeedbackEnabled")
        let newAnalyticsEnabled = keyValueStore.bool(forKey: "analyticsEnabled")
        let newFaceIdEnabled = keyValueStore.bool(forKey: "faceIdEnabled")
        let newCloudKitEnabled = keyValueStore.bool(forKey: "cloudKitEnabled")
        
        // Only update if values actually changed to avoid unnecessary UI updates
        if scriptureAutoFillEnabled != newScriptureAutoFillEnabled {
            scriptureAutoFillEnabled = newScriptureAutoFillEnabled
            userDefaults.set(newScriptureAutoFillEnabled, forKey: "scriptureAutoFillEnabled")
        }
        
        if let newTranslation = BibleTranslation(rawValue: newTranslationString), selectedTranslation != newTranslation {
            selectedTranslation = newTranslation
            userDefaults.set(newTranslationString, forKey: "selectedTranslation")
        }
        
        if memorizationSystemEnabled != newMemorizationSystemEnabled {
            memorizationSystemEnabled = newMemorizationSystemEnabled
            userDefaults.set(newMemorizationSystemEnabled, forKey: "memorizationSystemEnabled")
        }
        
        if hapticFeedbackEnabled != newHapticFeedbackEnabled {
            hapticFeedbackEnabled = newHapticFeedbackEnabled
            userDefaults.set(newHapticFeedbackEnabled, forKey: "hapticFeedbackEnabled")
        }
        
        if analyticsEnabled != newAnalyticsEnabled {
            analyticsEnabled = newAnalyticsEnabled
            userDefaults.set(newAnalyticsEnabled, forKey: "analyticsEnabled")
        }
        
        if faceIdEnabled != newFaceIdEnabled {
            faceIdEnabled = newFaceIdEnabled
            userDefaults.set(newFaceIdEnabled, forKey: "faceIdEnabled")
        }
        
        if cloudKitEnabled != newCloudKitEnabled {
            cloudKitEnabled = newCloudKitEnabled
            userDefaults.set(newCloudKitEnabled, forKey: "cloudKitEnabled")
        }
    }
    
    private func migrateUserDefaultsToCloudKit() {
        guard cloudKitEnabled else { return }
        
        // Check if migration has already been done
        let migrationKey = "settingsMigrationCompleted"
        if userDefaults.bool(forKey: migrationKey) { return }
        
        print("🔄 Migrating settings from UserDefaults to CloudKit...")
        
        // Migrate each setting if it exists in UserDefaults but not in CloudKit
        if userDefaults.object(forKey: "scriptureAutoFillEnabled") != nil && keyValueStore.object(forKey: "scriptureAutoFillEnabled") == nil {
            keyValueStore.set(userDefaults.bool(forKey: "scriptureAutoFillEnabled"), forKey: "scriptureAutoFillEnabled")
        }
        
        if let translation = userDefaults.string(forKey: "scriptureAutoFillTranslation"), keyValueStore.string(forKey: "selectedTranslation") == nil {
            keyValueStore.set(translation, forKey: "selectedTranslation")
        }
        
        if userDefaults.object(forKey: "memorizationSystemEnabled") != nil && keyValueStore.object(forKey: "memorizationSystemEnabled") == nil {
            keyValueStore.set(userDefaults.bool(forKey: "memorizationSystemEnabled"), forKey: "memorizationSystemEnabled")
        }
        
        if userDefaults.object(forKey: "hapticFeedbackEnabled") != nil && keyValueStore.object(forKey: "hapticFeedbackEnabled") == nil {
            keyValueStore.set(userDefaults.bool(forKey: "hapticFeedbackEnabled"), forKey: "hapticFeedbackEnabled")
        }
        
        if userDefaults.object(forKey: "analyticsEnabled") != nil && keyValueStore.object(forKey: "analyticsEnabled") == nil {
            keyValueStore.set(userDefaults.bool(forKey: "analyticsEnabled"), forKey: "analyticsEnabled")
        }
        
        if userDefaults.object(forKey: "faceIdEnabled") != nil && keyValueStore.object(forKey: "faceIdEnabled") == nil {
            keyValueStore.set(userDefaults.bool(forKey: "faceIdEnabled"), forKey: "faceIdEnabled")
        }
        
        keyValueStore.synchronize()
        userDefaults.set(true, forKey: migrationKey)
        
        print("✅ Settings migration to CloudKit completed")
    }
    
    // MARK: - Manual Sync Methods
    
    func forceSyncToCloud() {
        guard cloudKitEnabled else { return }
        
        keyValueStore.set(scriptureAutoFillEnabled, forKey: "scriptureAutoFillEnabled")
        keyValueStore.set(selectedTranslation.rawValue, forKey: "selectedTranslation")
        keyValueStore.set(memorizationSystemEnabled, forKey: "memorizationSystemEnabled")
        keyValueStore.set(hapticFeedbackEnabled, forKey: "hapticFeedbackEnabled")
        keyValueStore.set(analyticsEnabled, forKey: "analyticsEnabled")
        keyValueStore.set(faceIdEnabled, forKey: "faceIdEnabled")
        keyValueStore.set(cloudKitEnabled, forKey: "cloudKitEnabled")
        
        keyValueStore.synchronize()
        print("🔄 Force synced all settings to CloudKit")
    }
    
    func enableCloudKitSync() {
        cloudKitEnabled = true
        forceSyncToCloud()
    }
    
    func disableCloudKitSync() {
        cloudKitEnabled = false
        // Keep local settings but stop syncing
    }
}