//
//  CloudKitSyncService.swift
//  Christian Life Journal
//
//  Created by Claude on 8/27/25.
//

import Foundation
import SwiftUI
import CloudKit
import Network

class CloudKitSyncService: ObservableObject {
    static let shared = CloudKitSyncService()
    
    @Published var syncStatus: SyncStatus = .unknown
    @Published var isOnline: Bool = true
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    
    @AppStorage("cloudKitEnabled") private var cloudKitEnabled = false
    
    enum SyncStatus {
        case unknown
        case disabled           // CloudKit is turned off
        case unavailable        // iCloud account not available
        case syncing           // Currently syncing
        case synced            // Everything up to date
        case error             // Sync error occurred
        case offline           // No network connection
        
        var displayText: String {
            switch self {
            case .unknown: return "Checking..."
            case .disabled: return "Local Only"
            case .unavailable: return "iCloud Unavailable"
            case .syncing: return "Syncing..."
            case .synced: return "Synced"
            case .error: return "Sync Error"
            case .offline: return "Offline"
            }
        }
        
        var iconName: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .disabled: return "internaldrive"
            case .unavailable: return "exclamationmark.icloud"
            case .syncing: return "icloud.and.arrow.up.and.arrow.down"
            case .synced: return "icloud.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .offline: return "wifi.slash"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .unknown: return .secondary
            case .disabled: return .secondary
            case .unavailable: return .orange
            case .syncing: return .blue
            case .synced: return .appGreenDark
            case .error: return .red
            case .offline: return .orange
            }
        }
        
        var shouldAnimate: Bool {
            switch self {
            case .syncing: return true
            default: return false
            }
        }
    }
    
    private init() {
        startNetworkMonitoring()
        updateSyncStatus()
    }
    
    // MARK: - Public Methods
    
    func refreshSyncStatus() {
        updateSyncStatus()
    }
    
    func simulateSync() {
        guard cloudKitEnabled && isOnline else { return }
        
        Task { @MainActor in
            syncStatus = .syncing
            
            // Simulate sync process
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            syncStatus = .synced
            lastSyncDate = Date()
        }
    }
    
    // MARK: - Private Methods
    
    private func updateSyncStatus() {
        Task { @MainActor in
            if !cloudKitEnabled {
                syncStatus = .disabled
                return
            }
            
            if !isOnline {
                syncStatus = .offline
                return
            }
            
            // Check CloudKit availability
            let accountStatus = await checkCloudKitAccountStatus()
            
            switch accountStatus {
            case .available:
                // For now, assume synced when everything is available
                // In a real implementation, you'd check actual sync state
                syncStatus = .synced
                if lastSyncDate == nil {
                    lastSyncDate = Date()
                }
            case .noAccount, .restricted, .couldNotDetermine:
                syncStatus = .unavailable
            case .temporarilyUnavailable:
                syncStatus = .error
            @unknown default:
                syncStatus = .unknown
            }
        }
    }
    
    private func checkCloudKitAccountStatus() async -> CKAccountStatus {
        #if canImport(CloudKit)
        return await withCheckedContinuation { continuation in
            CKContainer(identifier: "iCloud.colbyacorcoran.Christian-Life-Journal")
                .accountStatus { status, error in
                    if let error = error {
                        print("CloudKit account status error: \(error)")
                    }
                    continuation.resume(returning: status)
                }
        }
        #else
        return .couldNotDetermine
        #endif
    }
    
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
                self?.updateSyncStatus()
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
}

// MARK: - Sync Status Components

struct SyncStatusIndicator: View {
    @StateObject private var syncService = CloudKitSyncService.shared
    let showText: Bool
    let size: CGFloat
    
    init(showText: Bool = true, size: CGFloat = 16) {
        self.showText = showText
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: syncService.syncStatus.iconName)
                .foregroundColor(syncService.syncStatus.iconColor)
                .font(.system(size: size, weight: .medium))
                .symbolEffect(.pulse, isActive: syncService.syncStatus.shouldAnimate)
            
            if showText {
                Text(syncService.syncStatus.displayText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            syncService.refreshSyncStatus()
        }
    }
}

struct DetailedSyncStatus: View {
    @StateObject private var syncService = CloudKitSyncService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                SyncStatusIndicator(showText: true)
                Spacer()
                if syncService.syncStatus == .synced, let lastSync = syncService.lastSyncDate {
                    Text("Last sync: \(formatSyncDate(lastSync))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if case .error = syncService.syncStatus, let error = syncService.syncError {
                Text(error.localizedDescription)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private func formatSyncDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDate(date, inSameDayAs: Date()) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Navigation Bar Sync Indicator

struct NavigationSyncIndicator: View {
    var body: some View {
        SyncStatusIndicator(showText: false, size: 14)
    }
}