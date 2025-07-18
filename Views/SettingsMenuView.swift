//
//  SettingsMenuView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/18/25.
//

import SwiftUI

struct SettingsMenuView: View {
    var body: some View {
        VStack(spacing: 24) {
            // App logo and version
            VStack(spacing: 4) {
                Image(systemName: "leaf.fill") // Replace with your logo if you have one
                    .resizable()
                    .frame(width: 48, height: 48)
                    .foregroundColor(.appGreenDark)
                Text("Christian Life Journal")
                    .font(.headline)
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("iOS \(UIDevice.current.systemVersion)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)

            Divider()

            ScrollView {
                // Settings options
                VStack(alignment: .leading, spacing: 18) {
                    Button(action: { /* TODO: Tag Management */ }) {
                        Label("Tag Management", systemImage: "tag.circle")
                    }
                    Button(action: { /* TODO: Speaker Management */ }) {
                        Label("Speaker Management", systemImage: "person.crop.circle")
                    }
                    
                    Toggle(isOn: .constant(false)) {
                        Label("Use FaceID", systemImage: "faceid")
                    }
                    .disabled(true) // Makes it non-interactive
                    
                    Toggle(isOn: .constant(false)) {
                        Label("Use FaceID", systemImage: "faceid")
                    }
                    .disabled(true) // Makes it non-interactive
                    

                    Toggle(isOn: .constant(false)) {
                        Label("Use iCloud Syncing", systemImage: "arrow.trianglehead.2.clockwise.rotate.90.icloud")
                    }
                    .disabled(true) // Makes it non-interactive
                    
                    
                    Button(action: { /* TODO: Help & Feedback */ }) {
                        Label("Feedback Board", systemImage: "questionmark.circle")
                    }
                    Button(action: { /* TODO: Contact */ }) {
                        Label("Contact", systemImage: "envelope.circle")
                    }
                    Button(action: { /* TODO: Terms & Privacy */ }) {
                        Label("Terms & Privacy Policy", systemImage: "document.circle")
                    }
                    
                }
                .buttonStyle(.plain)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
           

            
        }
        .padding()
        .frame(width: 320, height: 520)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.appWhite)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
    }
}

struct SettingsMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsMenuView()
    }
}

