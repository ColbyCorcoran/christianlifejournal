//
//  AuthenticationView.swift
//  Christian Life Journal
//
//  Created by Claude on 8/27/25.
//

import SwiftUI
import LocalAuthentication

struct AuthenticationView: View {
    @StateObject private var authService = BiometricAuthService.shared
    @State private var showingRetryAlert = false
    @State private var isAuthenticating = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Icon and Title
            VStack(spacing: 16) {
                Image(systemName: "leaf.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.appGreenDark)
                
                Text("Christian Life Journal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.appGreenDark)
                
                Text("Your personal spiritual journey")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Authentication Section
            VStack(spacing: 20) {
                // Biometric icon
                Image(systemName: authService.biometricIcon)
                    .font(.system(size: 60))
                    .foregroundColor(.appGreenDark)
                
                Text("Authentication Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Please authenticate to access your journal")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Authentication Button
                Button(action: {
                    authenticateUser()
                }) {
                    HStack {
                        if isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: authService.biometricIcon)
                        }
                        
                        Text(isAuthenticating ? "Authenticating..." : "Authenticate with \(authService.biometricTypeString)")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appGreenDark)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.headline)
                }
                .disabled(isAuthenticating)
                .padding(.horizontal)
                
                // Fallback button for passcode
                if authService.biometricType != .none {
                    Button("Use Passcode") {
                        authenticateWithPasscode()
                    }
                    .foregroundColor(.appGreenDark)
                    .font(.body)
                }
            }
            
            Spacer()
            
            // Error message
            if let error = authService.authenticationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
        }
        .padding()
        .background(Color.appWhite.ignoresSafeArea())
        .onAppear {
            // Automatically attempt authentication when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                authenticateUser()
            }
        }
        .alert("Authentication Failed", isPresented: $showingRetryAlert) {
            Button("Retry") {
                authenticateUser()
            }
            Button("Use Passcode") {
                authenticateWithPasscode()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Would you like to try again or use your device passcode?")
        }
    }
    
    private func authenticateUser() {
        isAuthenticating = true
        
        Task {
            let success = await authService.authenticate()
            
            await MainActor.run {
                isAuthenticating = false
                
                if !success {
                    showingRetryAlert = true
                }
            }
        }
    }
    
    private func authenticateWithPasscode() {
        isAuthenticating = true
        
        Task {
            _ = await authService.authenticateWithPasscode()
            
            await MainActor.run {
                isAuthenticating = false
            }
        }
    }
}

// MARK: - Preview

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}