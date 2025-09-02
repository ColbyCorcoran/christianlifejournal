//
//  ScriptureAutoFillTestView.swift
//  Christian Life Journal
//
//  Created by Claude on 8/29/25.
//  Test view for scripture auto-fill functionality
//

import SwiftUI

struct ScriptureAutoFillTestView: View {
    @State private var testText = ""
    @State private var titleText = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Scripture Auto-Fill Demo")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.appGreenDark)
                    
                    Text("Try typing these scripture references and tap the auto-fill button:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• John 3:16")
                        Text("• Romans 8:28")
                        Text("• Psalms 23:1-3")
                        Text("• Matt 5:8")
                        Text("• Genesis 1:1")
                    }
                    .font(.caption)
                    .foregroundColor(.appGreenDark)
                    .padding(.horizontal)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Title Field Test:")
                            .font(.headline)
                            .foregroundColor(.appGreenDark)
                        
                        ScriptureAutoFillTextField(
                            text: $titleText,
                            placeholder: "Enter title with scripture reference...",
                            axis: .horizontal
                        )
                        
                        Text("Notes Field Test:")
                            .font(.headline)
                            .foregroundColor(.appGreenDark)
                        
                        ScriptureAutoFillTextEditor(
                            text: $testText,
                            placeholder: "Type your notes here. Include scripture references like John 3:16 or Romans 8:28 and see the auto-fill magic!"
                        )
                        .frame(minHeight: 200)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Auto-Fill Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ScriptureAutoFillTestView()
}
