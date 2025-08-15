//
//  ContextualSearchBar.swift
//  Christian Life Journal
//
//  Created by Claude on 8/15/25.
//

import SwiftUI

struct ContextualSearchBar: View {
    @Binding var searchText: String
    let placeholder: String
    let addButtonAction: () -> Void
    let addButtonLabel: String
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField(placeholder, text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
            )
            
            Button(action: addButtonAction) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.appGreenDark))
                    .shadow(radius: 3)
            }
            .accessibilityLabel(addButtonLabel)
        }
    }
}

// MARK: - Preview

struct ContextualSearchBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ContextualSearchBar(
                searchText: .constant(""),
                placeholder: "Search entries...",
                addButtonAction: {},
                addButtonLabel: "Add Entry"
            )
            
            ContextualSearchBar(
                searchText: .constant("sample text"),
                placeholder: "Search sermon notes...",
                addButtonAction: {},
                addButtonLabel: "Add Sermon Note"
            )
        }
        .padding()
        .background(Color.appWhite)
    }
}