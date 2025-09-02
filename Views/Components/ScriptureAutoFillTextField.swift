//
//  ScriptureAutoFillTextField.swift
//  Christian Life Journal
//
//  Created by Claude on 8/29/25.
//

import SwiftUI

struct ScriptureAutoFillTextField: View {
    @Binding var text: String
    let placeholder: String
    let axis: Axis
    @StateObject private var autoFillService = ScriptureAutoFillService()
    @State private var showAutoFillButton = false
    @State private var detectedReferences: [ScriptureReference] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(placeholder, text: $text, axis: axis)
                .textFieldStyle(.roundedBorder)
                .onChange(of: text) { oldValue, newValue in
                    DispatchQueue.main.async {
                        checkForScriptureReferences()
                    }
                }
            
            if showAutoFillButton && !detectedReferences.isEmpty {
                Button(action: autoFillReferences) {
                    HStack {
                        Image(systemName: "text.quote")
                        Text("Auto-fill \(detectedReferences.count) scripture reference\(detectedReferences.count == 1 ? "" : "s")")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .buttonStyle(.borderless)
            }
        }
    }
    
    private func checkForScriptureReferences() {
        detectedReferences = autoFillService.getUnexpandedReferences(in: text)
        showAutoFillButton = !detectedReferences.isEmpty
    }
    
    private func autoFillReferences() {
        let autoFilledText = autoFillService.processTextForAutoFill(text)
        text = autoFilledText
        
        // Re-check for any remaining unexpanded references
        DispatchQueue.main.async {
            checkForScriptureReferences()
        }
    }
}

struct ScriptureAutoFillTextEditor: View {
    @Binding var text: String
    let placeholder: String
    @StateObject private var autoFillService = ScriptureAutoFillService()
    @State private var showAutoFillButton = false
    @State private var detectedReferences: [ScriptureReference] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .onChange(of: text) { oldValue, newValue in
                        DispatchQueue.main.async {
                            checkForScriptureReferences()
                        }
                    }
                
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }
            .frame(minHeight: 100)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            
            if showAutoFillButton && !detectedReferences.isEmpty {
                Button(action: autoFillReferences) {
                    HStack {
                        Image(systemName: "text.quote")
                        if detectedReferences.count == 1 {
                            Text("Auto-fill \(detectedReferences.last?.displayReference ?? "scripture")")
                        } else {
                            Text("Auto-fill latest reference (\(detectedReferences.count) found)")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .buttonStyle(.borderless)
            }
        }
    }
    
    private func checkForScriptureReferences() {
        detectedReferences = autoFillService.getUnexpandedReferences(in: text)
        showAutoFillButton = !detectedReferences.isEmpty
    }
    
    private func autoFillReferences() {
        let autoFilledText = autoFillService.processTextForAutoFill(text)
        text = autoFilledText
        
        // Re-check for any remaining unexpanded references
        DispatchQueue.main.async {
            checkForScriptureReferences()
        }
    }
}

#Preview {
    VStack {
        ScriptureAutoFillTextField(
            text: .constant("Today I read John 3:16 and it was amazing!"),
            placeholder: "Enter your notes...",
            axis: .horizontal
        )
        
        ScriptureAutoFillTextEditor(
            text: .constant("Studying Romans 8:28 and Jeremiah 29:11 today."),
            placeholder: "Enter your detailed notes here..."
        )
    }
    .padding()
}