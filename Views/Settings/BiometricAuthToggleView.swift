//
//  BiometricAuthToggleView.swift
//  Christian Life Journal
//
//  Created by Claude on 8/27/25.
//

import SwiftUI
import LocalAuthentication

struct BiometricAuthToggleView: View {
    @StateObject private var authService = BiometricAuthService.shared
    @ObservedObject private var cloudSettings = CloudKitSettingsService.shared
    @State private var showUnsupportedAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(authService.biometricTypeString, systemImage: authService.biometricIcon)
                    .foregroundColor(authService.biometricType != .none ? .primary : .secondary)
                Spacer()
                Toggle("", isOn: $cloudSettings.faceIdEnabled)
                    .tint(.appGreenDark)
                    .disabled(authService.biometricType == .none)
            }
            .onChange(of: cloudSettings.faceIdEnabled) { oldValue, newValue in
                handleBiometricToggle(newValue: newValue)
                // Haptic feedback for important setting change
                HapticFeedbackService.shared.importantSettingChanged()
                // Track analytics for FaceID toggle
                if newValue {
                    AnalyticsService.shared.trackFaceIDEnabled()
                }
            }
            
            // Status text
            Group {
                if authService.biometricType == .none {
                    Text("⚠️ Biometric authentication is not available on this device")
                        .foregroundColor(.orange)
                } else if cloudSettings.faceIdEnabled {
                    Text("✅ App will require \(authService.biometricTypeString.lowercased()) to open")
                        .foregroundColor(.appGreenDark)
                } else {
                    Text("🔓 App will open without authentication")
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption2)
            .fixedSize(horizontal: false, vertical: true)
            
            // Test authentication button (for development/testing)
            if cloudSettings.faceIdEnabled {
                Button("Test Authentication") {
                    Task {
                        authService.logout()
                        _ = await authService.authenticate()
                    }
                }
                .font(.caption)
                .foregroundColor(.appGreenDark)
            }
            
            Text("Biometric Authentication adds an extra layer of privacy protection.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .onAppear {
            authService.checkBiometricSupport()
        }
        .alert("Biometric Authentication Unavailable", isPresented: $showUnsupportedAlert) {
            Button("OK") { 
                cloudSettings.faceIdEnabled = false
            }
        } message: {
            Text("This device doesn't support biometric authentication or it hasn't been set up in Settings.")
        }
    }
    
    private func handleBiometricToggle(newValue: Bool) {
        if newValue && authService.biometricType == .none {
            showUnsupportedAlert = true
            cloudSettings.faceIdEnabled = false
            return
        }
        
        if newValue {
            // When enabling, immediately test authentication
            Task {
                let success = await authService.authenticate()
                if !success {
                    await MainActor.run {
                        cloudSettings.faceIdEnabled = false
                    }
                } else {
                    // Reset auth state so it will require auth next app launch
                    await MainActor.run {
                        authService.logout()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct BiometricAuthToggleView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            BiometricAuthToggleView()
        }
    }
}
