//
//  HapticFeedbackToggleView.swift
//  Christian Life Journal
//
//  Created by Claude on 8/27/25.
//

import SwiftUI

struct HapticFeedbackToggleView: View {
    @StateObject private var hapticService = HapticFeedbackService.shared
    @ObservedObject private var cloudSettings = CloudKitSettingsService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Use Haptics", systemImage: cloudSettings.hapticFeedbackEnabled ? "iphone.radiowaves.left.and.right" : "iphone")
                Spacer()
                Toggle("", isOn: $cloudSettings.hapticFeedbackEnabled)
                    .tint(.appGreenDark)
            }
            .onChange(of: cloudSettings.hapticFeedbackEnabled) { oldValue, newValue in
                hapticService.isEnabled = newValue
                // Give immediate feedback when toggling
                if newValue {
                    // Delay slightly so the setting takes effect
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        hapticService.toggleChanged()
                    }
                }
            }
            
            // Status text
            Group {
                if cloudSettings.hapticFeedbackEnabled {
                    Text("Subtle vibrations enhance your interactions")
                        .foregroundColor(.appGreenDark)
                } else {
                    Text("No haptic feedback during app interactions")
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption2)
            .fixedSize(horizontal: false, vertical: true)
            
            // Test haptic button
            if cloudSettings.hapticFeedbackEnabled {
                Button("Test Haptic Feedback") {
                    hapticService.testHaptic()
                }
                .font(.caption)
                .foregroundColor(.appGreenDark)
            }
            
            Text("Haptic Feedback allows you to customize the feel of the app.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
    }
}

// MARK: - Preview

struct HapticFeedbackToggleView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            HapticFeedbackToggleView()
        }
    }
}
