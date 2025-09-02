//
//  AnalyticsToggleView.swift
//  Christian Life Journal
//
//  Created by Claude on 8/27/25.
//

import SwiftUI

struct AnalyticsToggleView: View {
    @StateObject private var analyticsService = AnalyticsService.shared
    @ObservedObject private var cloudSettings = CloudKitSettingsService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Analytics", systemImage: cloudSettings.analyticsEnabled ? "chart.bar.fill" : "chart.bar")
                Spacer()
                Toggle("", isOn: $cloudSettings.analyticsEnabled)
                    .tint(.appGreenDark)
            }
            .onChange(of: cloudSettings.analyticsEnabled) { oldValue, newValue in
                analyticsService.setAnalyticsEnabled(newValue)
                // Haptic feedback for setting change
                HapticFeedbackService.shared.toggleChanged()
            }
            
            // Status text
            Group {
                if cloudSettings.analyticsEnabled {
                    Text("Helps improve the app - no personal content is tracked")
                        .foregroundColor(.appGreenDark)
                } else {
                    Text("No usage data will be collected")
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption2)
            .fixedSize(horizontal: false, vertical: true)
            
            // Privacy note
            Text("We never track your journal content or personal information. We only use this to see which features are most used and most useful in order to provide the best experience possible.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
    }
}

// MARK: - Preview

struct AnalyticsToggleView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            AnalyticsToggleView()
        }
    }
}
