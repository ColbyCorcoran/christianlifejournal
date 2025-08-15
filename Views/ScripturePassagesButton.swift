//
//  ScripturePassagesButton.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/14/25.
//

import SwiftUI

struct ScripturePassagesButton: View {
    @Binding var selectedPassages: [ScripturePassageSelection]
    @Binding var showPicker: Bool
    let bibleBooks: [BibleBook]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scripture Passages")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.appGreenDark)
            
            Button(action: { showPicker = true }) {
                HStack {
                    if selectedPassages.isEmpty {
                        Text("Select Scripture")
                            .foregroundColor(.gray)
                    } else {
                        Text("\(selectedPassages.count) passage\(selectedPassages.count == 1 ? "" : "s") selected")
                            .foregroundColor(.appGreenDark)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    Image(systemName: "book")
                        .foregroundColor(.appGreenDark)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.appGreenDark, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedPassages.isEmpty ? Color.clear : Color.appGreenPale.opacity(0.3))
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Preview

struct ScripturePassagesButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Empty state
            ScripturePassagesButton(
                selectedPassages: .constant([]),
                showPicker: .constant(false),
                bibleBooks: bibleBooks
            )
            
            // With selections
            ScripturePassagesButton(
                selectedPassages: .constant([
                    ScripturePassageSelection(bookIndex: 0, chapter: 1, verse: 1, verseEnd: 3),
                    ScripturePassageSelection(bookIndex: 58, chapter: 5, verse: 16, verseEnd: 16)
                ]),
                showPicker: .constant(false),
                bibleBooks: bibleBooks
            )
        }
        .padding()
    }
}