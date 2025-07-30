//
//  SettingsMenuView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/18/25.
//

import SwiftUI

struct SettingsMenuView: View {
    @Binding var isPresented: Bool
    @Binding var settingsPage: SettingsPage
    @ObservedObject var speakerStore: SpeakerStore
    @ObservedObject var tagStore: TagStore
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"


    var body: some View {
        ZStack {
            switch settingsPage {
            case .main:
                VStack(spacing: 24) {
                    // App logo and version
                    VStack(spacing: 4) {
                        Image(systemName: "leaf.fill")
                            .resizable()
                            .frame(width: 48, height: 48)
                            .foregroundColor(.appGreenDark)
                        Text("Christian Life Journal")
                            .font(.headline)
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("iOS \(UIDevice.current.systemVersion)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 12)

                    Divider()

                    VStack(alignment: .leading, spacing: 18) {
                        Button(action: { settingsPage = .sectionControls }) {
                            Label("Section Controls", systemImage: "slider.horizontal.3")
                        }
                        Button(action: { settingsPage = .userExperienceControls }) {
                            Label("User Experience Controls", systemImage: "hand.tap")
                        }
                        Button(action: { settingsPage = .appInformation }) {
                            Label("App Information", systemImage: "info.circle")
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                }

            case .sectionControls:
                VStack(spacing: 18) {
                    HStack {
                        Button(action: { settingsPage = .main }) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.top, 8)
                    Text("Section Controls")
                        .font(.headline)
                        .padding(.bottom, 8)
                    VStack(alignment: .leading, spacing: 18) {
                        Button(action: { settingsPage = .tagManagement }) {
                            Label("Tag Management", systemImage: "tag.circle")
                        }
                        
                        Button(action: { settingsPage = .speakerManagement }) {
                            Label("Speaker Management", systemImage: "person.2")
                        }
                        Button(action: { settingsPage = .scriptureMemorization }) {
                            Label("Scripture Memorization System", systemImage: "switch.2")
                        }
                    }
                    Spacer()
                }

            case .userExperienceControls:
                VStack(spacing: 18) {
                    HStack {
                        Button(action: { settingsPage = .main }) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.top, 8)
                    Text("User Experience Controls")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 18) {
                        Toggle(isOn: .constant(false)) {
                            Label("FaceID", systemImage: "faceid")
                        }
                        .disabled(true)
                        
                        Toggle(isOn: .constant(false)) {
                            Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                        }
                        .disabled(true)
                        
                        Toggle(isOn: .constant(false)) {
                            Label("iCloud Sync", systemImage: "arrow.trianglehead.2.clockwise.rotate.90.icloud")
                        }
                        .disabled(true)
                    }
                    
                    Spacer()
                }

            case .appInformation:
                VStack(spacing: 18) {
                    HStack {
                        Button(action: { settingsPage = .main }) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.top, 8)
                    Text("App Information")
                        .font(.headline)
                        .padding(.bottom, 8)
                    VStack(alignment: .leading, spacing: 18) {
                        Button(action: { /* TODO */ }) {
                            Label("Feedback Board", systemImage: "ellipsis.message")
                        }
                        Button(action: { /* TODO */ }) {
                            Label("Terms & Privacy Policy", systemImage: "text.document")
                        }
                        Button(action: { /* TODO */ }) {
                            Label("Contact", systemImage: "envelope")
                        }
                    }
                    Spacer()
                }

            case .tagManagement:
                TagManagementView(settingsPage: $settingsPage, tagStore: tagStore)

            case .speakerManagement:
                SpeakerManagementView(settingsPage: $settingsPage, speakerStore: speakerStore)

            case .scriptureMemorization:
                VStack(spacing: 18) {
                    HStack {
                        Button(action: { settingsPage = .sectionControls }) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.top, 8)
                    
                    Text("Scripture Memorization System")
                        .font(.headline)
                        .padding(.bottom, 8)
                    Text("Our app utilizes a three-phase memorization system and will guide you through each of the 3 phases for each verse you choose to memorize. If you do not wish to use this system, and instead want the 'Scripture Memorization' section of this app to simply be flashcards, turn this toggle off. This will change the way the section will function and look.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Toggle(isOn: .constant(true)) {
                        Label("Memorization System", systemImage: "book")
                    }
                    .disabled(true)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .frame(width: 340, height: 380)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.appWhite)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
    }
}

struct SettingsMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsMenuView(isPresented: .constant(true), settingsPage: .constant(.main), speakerStore: SpeakerStore(), tagStore: TagStore())
    }
}
