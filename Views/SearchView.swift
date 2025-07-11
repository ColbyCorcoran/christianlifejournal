//
//  SearchView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/11/25.
//

import SwiftUI

struct SearchView: View {
    @Binding var searchText: String
    let allEntries: [JournalEntry]
    @Binding var showSearch: Bool
    @FocusState private var isSearchFocused: Bool

    var filteredEntries: [JournalEntry] {
        guard !searchText.isEmpty else { return [] }
        let lower = searchText.lowercased()
        return allEntries.filter {
            ($0.title.lowercased().contains(lower) && !$0.title.isEmpty) ||
            ($0.scripture?.lowercased().contains(lower) ?? false) ||
            ($0.notes?.lowercased().contains(lower) ?? false)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.appWhite.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.appGreenDark)
                        TextField("Search journal...", text: $searchText)
                            .focused($isSearchFocused)
                            .submitLabel(.search)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.appGreenPale)
                    )

                    Button(action: {
                        showSearch = false
                    }) {
                        Text("Cancel")
                            .foregroundColor(.appGreenDark)
                            .padding(.leading, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60) // Adjust as needed for safe area
                .padding(.bottom, 12)

                if searchText.isEmpty {
                    Spacer()
                    Text("Type to search your journal entries.")
                        .foregroundColor(.appGreen)
                        .font(.body)
                    Spacer()
                } else if filteredEntries.isEmpty {
                    Spacer()
                    Text("No results found.")
                        .foregroundColor(.appGreen)
                        .font(.body)
                    Spacer()
                } else {
                    List(filteredEntries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title.isEmpty ? (entry.scripture ?? "Untitled") : entry.title)
                                .font(.headline)
                            Text(formattedDate(entry.date))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.plain)
                    .background(Color.appWhite)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFocused = true
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(searchText: .constant(""), allEntries: [], showSearch: .constant(true))
    }
}
