//
//  NewSettingsView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/13/25.
//

import SwiftUI

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
    @EnvironmentObject var memorizationSettings: MemorizationSettings
    
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
                        .frame(width: 24, height: 24)
                        .foregroundColor(.appGreenDark)
                    
                    Text("Christian Life Journal")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appGreenDark)
                    
                    Text("Version \(appVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.appGreenPale.opacity(0.1))
    }
    
    @ViewBuilder
    private var scriptureMemorizationSection: some View {
        Section("Scripture Memorization") {
            Toggle(isOn: $memorizationSettings.isSystemEnabled) {
                Label("Enable Memory System", systemImage: memorizationSettings.isSystemEnabled ? "book.closed.fill" : "book.closed")
            }
            .tint(.appGreenDark)
            
            VStack(alignment: .leading, spacing: 8) {
                if memorizationSettings.isSystemEnabled {
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
        }
    }
    
    
    
    @ViewBuilder
    private var userExperienceSection: some View {
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
                            .frame(width: 24, height: 24)
                            .foregroundColor(.appGreenDark)
                        
                        Text("Christian Life Journal")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.appGreenDark)
                        
                        Text("Version \(appVersion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
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
