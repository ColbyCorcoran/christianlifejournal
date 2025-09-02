//
//  CloudKitMigrationService.swift
//  Christian Life Journal
//
//  Created by Claude on 8/27/25.
//

import Foundation
import SwiftData
import CloudKit
import SwiftUI

class CloudKitMigrationService: ObservableObject {
    static let shared = CloudKitMigrationService()
    
    @Published var migrationStatus: MigrationStatus = .idle
    @Published var migrationProgress: Double = 0.0
    @Published var migrationMessage: String = ""
    
    private init() {}
    
    enum MigrationStatus {
        case idle
        case preparingForCloudKit
        case migratingToCloudKit
        case preparingForLocal
        case migratingToLocal
        case completed
        case failed(Error)
    }
    
    // MARK: - Public Methods
    
    /// Enable CloudKit syncing
    /// This triggers an app restart to reinitialize the ModelContainer with CloudKit
    func enableCloudKit() {
        Task { @MainActor in
            migrationStatus = .preparingForCloudKit
            migrationMessage = "Preparing to enable iCloud sync..."
            
            // Set the CloudKit enabled flag
            UserDefaults.standard.set(true, forKey: "cloudKitEnabled")
            
            // Show user notification about restart
            NotificationCenter.default.post(
                name: .cloudKitToggleChanged,
                object: nil,
                userInfo: ["enabled": true, "requiresRestart": true]
            )
            
            migrationStatus = .completed
            migrationMessage = "iCloud sync will be enabled when you restart the app."
        }
    }
    
    /// Disable CloudKit syncing
    /// This moves back to local-only storage
    func disableCloudKit() {
        Task { @MainActor in
            migrationStatus = .preparingForLocal
            migrationMessage = "Switching to local storage..."
            
            // Set the CloudKit disabled flag
            UserDefaults.standard.set(false, forKey: "cloudKitEnabled")
            
            // Show user notification about restart
            NotificationCenter.default.post(
                name: .cloudKitToggleChanged,
                object: nil,
                userInfo: ["enabled": false, "requiresRestart": true]
            )
            
            migrationStatus = .completed
            migrationMessage = "Local storage mode will be enabled when you restart the app."
        }
    }
    
    /// Check if CloudKit is available for the current user
    func checkCloudKitAvailability() async -> CKAccountStatus {
        #if canImport(CloudKit)
        return await withCheckedContinuation { continuation in
            // Use placeholder container identifier
            CKContainer(identifier: "iCloud.colbyacorcoran.Christian-Life-Journal")
                .accountStatus { status, error in
                    continuation.resume(returning: status)
                }
        }
        #else
        return .couldNotDetermine
        #endif
    }
    
    /// Validate that CloudKit setup is working
    func validateCloudKitSetup() async -> Bool {
        let status = await checkCloudKitAvailability()
        return status == .available
    }
    
    /// Reset migration status
    func resetStatus() {
        Task { @MainActor in
            migrationStatus = .idle
            migrationProgress = 0.0
            migrationMessage = ""
        }
    }
    
    // MARK: - Migration Helpers
    
    /// Show restart prompt to user
    static func showRestartPrompt() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .showRestartPrompt, object: nil)
        }
    }
    
    /// Handle automatic restart (iOS will handle this)
    static func requestAppRestart() {
        // iOS doesn't allow programmatic app restart
        // The ModelContainer change will take effect on next app launch
        showRestartPrompt()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let cloudKitToggleChanged = Notification.Name("cloudKitToggleChanged")
    static let showRestartPrompt = Notification.Name("showRestartPrompt")
}

// MARK: - Migration Status Helpers

extension CloudKitMigrationService.MigrationStatus {
    var isInProgress: Bool {
        switch self {
        case .preparingForCloudKit, .migratingToCloudKit, .preparingForLocal, .migratingToLocal:
            return true
        default:
            return false
        }
    }
    
    var displayMessage: String {
        switch self {
        case .idle:
            return "Ready"
        case .preparingForCloudKit:
            return "Preparing iCloud sync..."
        case .migratingToCloudKit:
            return "Enabling iCloud sync..."
        case .preparingForLocal:
            return "Preparing local storage..."
        case .migratingToLocal:
            return "Switching to local storage..."
        case .completed:
            return "Ready - restart app to complete"
        case .failed(let error):
            return "Error: \(error.localizedDescription)"
        }
    }
}