//
//  CloudKitMigrationView.swift
//  Christian Life Journal
//
//  Created by Claude on 8/27/25.
//

import SwiftUI

struct CloudKitMigrationView: View {
    @StateObject private var migrationService = CloudKitMigrationService.shared
    @State private var showRestartAlert = false
    @State private var restartMessage = ""
    
    var body: some View {
        EmptyView()
            .onReceive(NotificationCenter.default.publisher(for: .cloudKitToggleChanged)) { notification in
                handleCloudKitToggle(notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: .showRestartPrompt)) { _ in
                showRestartPrompt()
            }
            .alert("App Restart Required", isPresented: $showRestartAlert) {
                Button("OK") {
                    // User acknowledges restart requirement
                }
            } message: {
                Text(restartMessage)
            }
    }
    
    private func handleCloudKitToggle(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let enabled = userInfo["enabled"] as? Bool,
              let requiresRestart = userInfo["requiresRestart"] as? Bool else {
            return
        }
        
        if requiresRestart {
            let syncType = enabled ? "iCloud sync" : "local storage"
            restartMessage = "Please close and reopen the app to switch to \(syncType) mode. Your data will be preserved."
            showRestartAlert = true
        }
    }
    
    private func showRestartPrompt() {
        restartMessage = "Changes will take effect when you restart the app. Your data will be safely preserved."
        showRestartAlert = true
    }
}

// MARK: - Migration Status Indicator

struct MigrationStatusView: View {
    @StateObject private var migrationService = CloudKitMigrationService.shared
    
    var body: some View {
        if migrationService.migrationStatus.isInProgress {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                
                Text(migrationService.migrationStatus.displayMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.appGreenPale.opacity(0.3))
            )
        }
    }
}

// MARK: - CloudKit Status Indicator

struct CloudKitStatusIndicator: View {
    @AppStorage("cloudKitEnabled") private var cloudKitEnabled = false
    @State private var isOnline = true // Would be connected to network monitoring
    
    var body: some View {
        if cloudKitEnabled {
            HStack(spacing: 4) {
                Image(systemName: isOnline ? "icloud.fill" : "icloud.slash")
                    .foregroundColor(isOnline ? .appGreenDark : .orange)
                    .font(.caption)
                
                Text(isOnline ? "Synced" : "Offline")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}