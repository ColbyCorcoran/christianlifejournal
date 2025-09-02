//
//  BiometricAuthService.swift
//  Christian Life Journal
//
//  Created by Claude on 8/27/25.
//

import Foundation
import LocalAuthentication
import SwiftUI

class BiometricAuthService: ObservableObject {
    static let shared = BiometricAuthService()
    
    @Published var isAuthenticated = false
    @Published var authenticationError: String?
    @Published var biometricType: LABiometryType = .none
    
    @AppStorage("faceIdEnabled") private var faceIdEnabled = false
    
    private init() {
        checkBiometricSupport()
    }
    
    // MARK: - Public Methods
    
    func checkBiometricSupport() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
        }
    }
    
    func authenticate() async -> Bool {
        guard faceIdEnabled else {
            await MainActor.run {
                isAuthenticated = true
            }
            return true
        }
        
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            let errorMessage = error?.localizedDescription ?? "Biometric authentication is not available"
            await MainActor.run {
                authenticationError = errorMessage
                isAuthenticated = false
            }
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access your Christian Life Journal"
            )
            
            await MainActor.run {
                isAuthenticated = success
                authenticationError = nil
                
                // Haptic feedback
                if success {
                    HapticFeedbackService.shared.authenticationSuccess()
                } else {
                    HapticFeedbackService.shared.authenticationFailed()
                }
            }
            
            return success
        } catch {
            await MainActor.run {
                authenticationError = error.localizedDescription
                isAuthenticated = false
                HapticFeedbackService.shared.authenticationFailed()
            }
            
            return false
        }
    }
    
    func authenticateWithPasscode() async -> Bool {
        let context = LAContext()
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Authenticate to access your Christian Life Journal"
            )
            
            await MainActor.run {
                isAuthenticated = success
                authenticationError = nil
                
                // Haptic feedback
                if success {
                    HapticFeedbackService.shared.authenticationSuccess()
                } else {
                    HapticFeedbackService.shared.authenticationFailed()
                }
            }
            
            return success
        } catch {
            await MainActor.run {
                authenticationError = error.localizedDescription
                isAuthenticated = false
                HapticFeedbackService.shared.authenticationFailed()
            }
            
            return false
        }
    }
    
    func logout() {
        isAuthenticated = false
    }
    
    func requiresAuthentication() -> Bool {
        return faceIdEnabled && !isAuthenticated
    }
    
    // MARK: - Helper Methods
    
    var biometricTypeString: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Biometric Authentication"
        @unknown default:
            return "Biometric Authentication"
        }
    }
    
    var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "person.badge.key"
        @unknown default:
            return "person.badge.key"
        }
    }
}