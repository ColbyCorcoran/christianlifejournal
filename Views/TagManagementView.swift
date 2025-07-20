//
//  TagManagementView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/19/25.
//

import SwiftUI

struct TagManagementView: View {
    @Binding var settingsPage: SettingsPage
    @State private var tags: [String] = ["Prayer", "Study", "Sermon"]
    @State private var newTag: String = ""

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button(action: { settingsPage = .sectionControls }) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.top, 8)
            Text("Tag Management")
                .font(.headline)
                .padding(.bottom, 8)

            List {
                ForEach(tags, id: \.self) { tag in
                    HStack {
                        Text(tag)
                        Spacer()
                        Button(action: {
                            // TODO: Edit tag
                        }) {
                            Image(systemName: "pencil")
                        }
                        Button(action: {
                            tags.removeAll { $0 == tag }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .frame(maxHeight: 200)

            HStack {
                TextField("New Tag", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Create") {
                    if !newTag.trimmingCharacters(in: .whitespaces).isEmpty {
                        tags.append(newTag)
                        newTag = ""
                    }
                }
            }
            .padding(.top, 8)
            Spacer()
        }
        .padding()
        .frame(width: 340, height: 420)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.appWhite)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
    }
}

