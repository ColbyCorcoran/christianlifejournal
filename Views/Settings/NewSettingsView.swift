//
//  NewSettingsView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/13/25.
//

import SwiftUI
import CloudKit

// Minimal enum for legacy management views
enum SettingsPage {
    case tagManagement
    case speakerManagement
    case prayerCategoryManagement
}

struct NewSettingsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var speakerStore: SpeakerStore
    @EnvironmentObject var prayerCategoryStore: PrayerCategoryStore
    @EnvironmentObject var binderStore: BinderStore
// Using cloudSettings directly instead of separate memorizationSettings
// Using cloudSettings directly for auto-fill
    @ObservedObject private var cloudSettings = CloudKitSettingsService.shared
    
    // CloudKit state variables
    @State private var cloudKitStatus: CKAccountStatus = .couldNotDetermine
    @State private var showCloudKitAlert = false
    @StateObject private var migrationService = CloudKitMigrationService.shared
    
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    
    var body: some View {
        NavigationView {
            List {
                appHeaderSection
                tagsManagementSection
                scriptureMemorizationSection
                userExperienceSection
                appInformationSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.appGreenDark)
                    .fontWeight(.medium)
                }
            })
        }
        .onAppear {
            checkCloudKitStatus()
        }
        .alert("iCloud Not Available", isPresented: $showCloudKitAlert) {
            Button("Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please sign in to iCloud in Settings to enable syncing.")
        }
        .background(
            CloudKitMigrationView()
        )
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var appHeaderSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.appGreenDark)
                    
                    Text("Christian Life Journal")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.appGreenDark)
                    
                    Text("Version \(appVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(Color.appGreenPale.opacity(0.1))
    }
    
    @ViewBuilder
    private var scriptureMemorizationSection: some View {
        Section("Scripture Memorization") {
            Toggle(isOn: $cloudSettings.memorizationSystemEnabled) {
                Label("Enable Memory System", systemImage: cloudSettings.memorizationSystemEnabled ? "book.closed.fill" : "book.closed")
            }
            .tint(.appGreenDark)
            .onChange(of: cloudSettings.memorizationSystemEnabled) { oldValue, newValue in
                AnalyticsService.shared.trackMemorizationSystemToggled(enabled: newValue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if cloudSettings.memorizationSystemEnabled {
                    Text("Active: 3-phase system with progress tracking")
                        .font(.caption)
                        .foregroundColor(.appGreenDark)
                        .fontWeight(.medium)
                } else {
                    Text("Inactive: Simple flashcard mode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Our three-phase memorization system guides you through intensive learning, daily review, and long-term retention. Turn off for simple flashcard mode.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private var tagsManagementSection: some View {
        Section("Data Management") {
            NavigationLink(destination: TagManagementSettingsView()) {
                Label("Manage Tags", systemImage: "tag")
            }
            
            NavigationLink(destination: SpeakerManagementSettingsView()) {
                Label("Manage Speakers", systemImage: "person.2")
            }
            
            NavigationLink(destination: PrayerCategoryManagementSettingsView()) {
                Label("Manage Prayer Categories", systemImage: "folder")
            }
            
            NavigationLink(destination: BinderManagementSettingsView()) {
                Label("Manage Binders", systemImage: "books.vertical")
            }
        }
    }
    
    
    
    @ViewBuilder
    private var userExperienceSection: some View {
        Section(content: {
            // Enhanced iCloud Sync (replacing the disabled placeholder)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("iCloud Sync", systemImage: cloudSettings.cloudKitEnabled ? "arrow.trianglehead.2.clockwise.rotate.90.icloud.fill" : "arrow.trianglehead.2.clockwise.rotate.90.icloud")
                    Spacer()
                    Toggle("", isOn: $cloudSettings.cloudKitEnabled)
                        .tint(.appGreenDark)
                        .disabled(cloudKitStatus != .available)
                }
                .onChange(of: cloudSettings.cloudKitEnabled) { oldValue, newValue in
                    handleCloudKitToggle(oldValue: oldValue, newValue: newValue)
                    // Haptic feedback for important setting change
                    HapticFeedbackService.shared.importantSettingChanged()
                }
                
                // Status text
                Group {
                    if cloudKitStatus == .available {
                        if cloudSettings.cloudKitEnabled {
                            Text("✅ Your journal data will sync across all your devices")
                                .foregroundColor(.appGreenDark)
                        } else {
                            Text("📱 Data is stored locally on this device only")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("⚠️ iCloud is not available. Check your iCloud settings.")
                            .foregroundColor(.orange)
                    }
                }
                .font(.caption2)
                .fixedSize(horizontal: false, vertical: true)
                
                // Migration status indicator
                if migrationService.migrationStatus.isInProgress {
                    MigrationStatusView()
                }
                
                // Detailed sync status when CloudKit is enabled
                if cloudSettings.cloudKitEnabled && cloudKitStatus == .available {
                    Divider()
                    
                    DetailedSyncStatus()
                    
                    // Development: Test sync button
                    #if DEBUG
                    Button("Test Sync") {
                        CloudKitSyncService.shared.simulateSync()
                    }
                    .font(.caption)
                    .foregroundColor(.appGreenDark)
                    .padding(.top, 4)
                    #endif
                }
                
                Text("iCloud Syncing keeps your journal data up to date across all your devices.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            
            // Biometric Authentication
            BiometricAuthToggleView()
            
            HapticFeedbackToggleView()
            
            // Usage Analytics
            AnalyticsToggleView()
            
            // Scripture Auto-Fill Settings
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Scripture Auto-Fill", systemImage: cloudSettings.scriptureAutoFillEnabled ? "quote.bubble.fill" : "quote.bubble")
                    Spacer()
                    Toggle("", isOn: $cloudSettings.scriptureAutoFillEnabled)
                        .tint(.appGreenDark)
                }
                
                if cloudSettings.scriptureAutoFillEnabled {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Translation:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Menu(cloudSettings.selectedTranslation.abbreviation) {
                                ForEach(BibleTranslation.allCases, id: \.rawValue) { translation in
                                    Button(translation.displayName) {
                                        cloudSettings.selectedTranslation = translation
                                    }
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.appGreenDark)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.appGreenPale.opacity(0.2))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.appGreenDark.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    
                } else {
                    Text("")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text("Automatically expand Scripture references in your journal entries to include the full verse text.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }, header: {
            Text("User Experience")
        })
    }
    
    @ViewBuilder
    private var appInformationSection: some View {
        Section(content: {
            Button(action: { /* TODO */ }) {
                Label("Feedback Board", systemImage: "ellipsis.message")
            }
            .foregroundColor(.secondary)
            .disabled(true)
            
            Button(action: { /* TODO */ }) {
                Label("Terms & Privacy", systemImage: "text.document")
            }
            .foregroundColor(.secondary)
            .disabled(true)
            
            Button(action: { /* TODO */ }) {
                Label("Contact Support", systemImage: "envelope")
            }
            .foregroundColor(.secondary)
            .disabled(true)
        }, header: {
            Text("App Information")
        }, footer: {
            Text("Support, feedback, and legal information")
                .font(.caption2)
        })
    }
    
    // MARK: - CloudKit Methods
    
    private func checkCloudKitStatus() {
        #if canImport(CloudKit)
        CKContainer(identifier: "iCloud.colbyacorcoran.Christian-Life-Journal")
            .accountStatus { status, error in
                DispatchQueue.main.async {
                    self.cloudKitStatus = status
                    print("CloudKit status: \(status), error: \(error?.localizedDescription ?? "none")")
                }
            }
        #else
        // CloudKit not available
        DispatchQueue.main.async {
            self.cloudKitStatus = .couldNotDetermine
            print("CloudKit not available in this build")
        }
        #endif
    }
    
    private func handleCloudKitToggle(oldValue: Bool, newValue: Bool) {
        // Check if CloudKit is available before allowing toggle
        if newValue && cloudKitStatus != .available {
            cloudSettings.cloudKitEnabled = false
            showCloudKitAlert = true
            return
        }
        
        // Handle the toggle change using migration service
        if newValue && !oldValue {
            // Enabling CloudKit
            migrationService.enableCloudKit()
            AnalyticsService.shared.trackCloudKitEnabled()
        } else if !newValue && oldValue {
            // Disabling CloudKit
            migrationService.disableCloudKit()
        }
    }
    
}

// MARK: - Preview

struct NewSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        // NUCLEAR OPTION: Avoid SwiftData entirely in preview
        NavigationView {
            SwiftDataFreePreviewNewSettingsView()
        }
    }
}

// MARK: - SwiftData-Free Preview Implementation

struct SwiftDataFreePreviewNewSettingsView: View {
    @State private var isSystemEnabled: Bool = true
    
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    
    var body: some View {
        List {
            // App Header Section
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.appGreenDark)
                        
                        Text("Christian Life Journal")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.appGreenDark)
                        
                        Text("Version \(appVersion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.appGreenPale.opacity(0.1))
            
            // Scripture Memorization Section
            Section("Scripture Memorization") {
                Toggle(isOn: $isSystemEnabled) {
                    Label("Enable Memory System", systemImage: isSystemEnabled ? "book.closed.fill" : "book.closed")
                }
                .tint(.appGreenDark)
                
                VStack(alignment: .leading, spacing: 8) {
                    if isSystemEnabled {
                        Text("Active: 3-phase system with progress tracking")
                            .font(.caption)
                            .foregroundColor(.appGreenDark)
                            .fontWeight(.medium)
                    } else {
                        Text("Inactive: Simple flashcard mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Our three-phase memorization system guides you through intensive learning, daily review, and long-term retention. Turn off for simple flashcard mode.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
            
            // Data Management Section
            Section("Data Management") {
                Label("Manage Tags", systemImage: "tag")
                Label("Manage Speakers", systemImage: "person.2")
                Label("Manage Prayer Categories", systemImage: "folder")
            }
            
            // User Experience Section
            Section(content: {
                HStack {
                    Label("FaceID Authentication", systemImage: "faceid")
                        .foregroundColor(.secondary)
                    Spacer()
                    Toggle("", isOn: .constant(false))
                        .disabled(true)
                }
                
                HStack {
                    Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                        .foregroundColor(.secondary)
                    Spacer()
                    Toggle("", isOn: .constant(false))
                        .disabled(true)
                }
                
                HStack {
                    Label("iCloud Sync", systemImage: "arrow.trianglehead.2.clockwise.rotate.90.icloud")
                        .foregroundColor(.secondary)
                    Spacer()
                    Toggle("", isOn: .constant(false))
                        .disabled(true)
                }
            }, header: {
                Text("User Experience")
            }, footer: {
                Text("Coming soon - personalization options")
                    .font(.caption2)
            })
            
            // App Information Section
            Section(content: {
                Button(action: { /* TODO */ }) {
                    Label("Feedback Board", systemImage: "ellipsis.message")
                }
                .foregroundColor(.secondary)
                .disabled(true)
                
                Button(action: { /* TODO */ }) {
                    Label("Terms & Privacy", systemImage: "text.document")
                }
                .foregroundColor(.secondary)
                .disabled(true)
                
                Button(action: { /* TODO */ }) {
                    Label("Contact Support", systemImage: "envelope")
                }
                .foregroundColor(.secondary)
                .disabled(true)
            }, header: {
                Text("App Information")
            }, footer: {
                Text("Support, feedback, and legal information")
                    .font(.caption2)
            })
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    // No-op for preview
                }
                .foregroundColor(.appGreenDark)
                .fontWeight(.medium)
            }
        })
    }
}
