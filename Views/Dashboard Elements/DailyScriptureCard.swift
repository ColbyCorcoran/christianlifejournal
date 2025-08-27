//
//  DailyScriptureCard.swift
//  Christian Life Journal
//
//  Daily rotating scripture display card for dashboard
//

import SwiftUI

struct DailyScriptureCard: View {
    @EnvironmentObject var scriptureManager: DailyScriptureManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Scripture text with truncation
            VStack(alignment: .leading, spacing: 8) {
                Text(scriptureManager.currentScripture.text)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .italic()
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    // Optional refresh button (you can remove this if you want it to only change daily)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            scriptureManager.refreshScripture()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(.appGreenDark.opacity(0.6))
                    }
                    Spacer()
                    Text("— " + scriptureManager.currentScripture.reference)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.appGreenDark)
                }
            }
            .padding(.vertical, 8)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appGreenPale.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appGreenDark.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct DailyScriptureCard_Previews: PreviewProvider {
    static var previews: some View {
        DailyScriptureCard()
            .environmentObject(DailyScriptureManager())
            .padding()
    }
}
