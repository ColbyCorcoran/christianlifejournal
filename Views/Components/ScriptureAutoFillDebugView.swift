//
//  ScriptureAutoFillDebugView.swift
//  Christian Life Journal
//
//  Debug view to test pattern matching
//

import SwiftUI

struct ScriptureAutoFillDebugView: View {
    @State private var testText = ""
    @StateObject private var autoFillService = ScriptureAutoFillService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Scripture Pattern Debug")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Test Text:")
                        .font(.headline)
                    
                    TextEditor(text: $testText)
                        .frame(height: 200)
                        .border(Color.gray, width: 1)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected References:")
                        .font(.headline)
                    
                    let allReferences = autoFillService.detectScriptureReferences(in: testText)
                    let unexpandedReferences = autoFillService.getUnexpandedReferences(in: testText)
                    
                    Text("All References Found: \(allReferences.count)")
                        .foregroundColor(.blue)
                    
                    ForEach(Array(allReferences.enumerated()), id: \.offset) { index, ref in
                        Text("• \(ref.originalText) → \(ref.displayReference)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Text("Unexpanded References: \(unexpandedReferences.count)")
                        .foregroundColor(.orange)
                    
                    ForEach(Array(unexpandedReferences.enumerated()), id: \.offset) { index, ref in
                        Text("• \(ref.originalText) → \(ref.displayReference)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Button("Test Auto-Fill") {
                    let processed = autoFillService.processTextForAutoFill(testText)
                    testText = processed
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Pattern Debug")
            .onAppear {
                testText = "Romans 8:28 - And we know that all things work together for good to them that love God, to them who are the called according to his purpose. John 3:16 - For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life. Matt 5:3"
            }
        }
    }
}

#Preview {
    ScriptureAutoFillDebugView()
}