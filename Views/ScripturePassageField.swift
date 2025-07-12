//
//  ScripturePassageField.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/11/25.
//

import SwiftUI

struct ScripturePassageField: View {
    @Binding var text: String
    @Binding var reference: ScriptureReference?
    let bibleBooks: [BibleBook]

    @State private var showSuggestions = false
    @State private var query = ""
    @FocusState private var isFocused: Bool

    var filteredBooks: [BibleBook] {
        guard !query.isEmpty else { return [] }
        let lower = query.lowercased()
        return bibleBooks.filter { book in
            book.name.lowercased().hasPrefix(lower) ||
            book.abbreviations.contains(where: { $0.lowercased().hasPrefix(lower) })
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            TextField("Scripture Passage", text: $query, onEditingChanged: { editing in
                showSuggestions = editing
            }, onCommit: {
                text = query
                reference = parseScriptureReference(query, bibleBooks: bibleBooks)
                showSuggestions = false
            })
            .autocapitalization(.words)
            .disableAutocorrection(true)
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.appWhite))
            .focused($isFocused)
            .onChange(of: query) { newValue, _ in
                text = newValue
                reference = parseScriptureReference(newValue, bibleBooks: bibleBooks)
            }
            }

            if showSuggestions && !filteredBooks.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredBooks, id: \.name) { book in
                            Button(action: {
                                query = book.name + " "
                                isFocused = true
                                showSuggestions = false
                            }) {
                                Text(book.name)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.appWhite))
                .frame(maxHeight: 120)
            }

            if let ref = reference, !ref.isValid, !ref.raw.isEmpty {
                Text(ref.error ?? "Invalid reference")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
}


