//
//  TagManagementView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/19/25.
//

import SwiftUI

struct TagManagementView: View {
    @Binding var settingsPage: SettingsPage
    @EnvironmentObject var tagStore: TagStore
    @State private var newTag: String = ""
    @State private var editingTagId: UUID? = nil
    @State private var editedTag: String = ""
    @State private var tagToDelete: UUID? = nil

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
            Text("\(Image(systemName: "tag.circle")) Tag Management")
                .font(.headline)
            
            Text("Our app uses default, auto-applied tags for each book of the Bible and each app section. These tags will only display as a filter in search. The list below will only display the tags that you create.")
                .font(.caption2)
                .padding(.bottom, 8)

            List {
                ForEach(tagStore.userTags, id: \.id) { tag in
                    HStack {
                        if editingTagId == tag.id {
                            TextField("Tag Name", text: $editedTag)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("Save") {
                                if !editedTag.trimmingCharacters(in: .whitespaces).isEmpty {
                                    tagStore.updateUserTag(withId: tag.id, newName: editedTag)
                                }
                                editingTagId = nil
                                editedTag = ""
                            }
                            .buttonStyle(.bordered)
                            .tint(.appGreenDark)
                            
                            Button("Cancel") {
                                editingTagId = nil
                                editedTag = ""
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Text(tag.name)
                            Spacer()
                            Button(action: {
                                editedTag = tag.name
                                editingTagId = tag.id
                            }) {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.plain)
                            Button(action: {
                                tagToDelete = tag.id
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .cornerRadius(10)
            .background(Color.appWhite)

            HStack {
                TextField("New Tag", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Create") {
                    let trimmed = newTag.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty && !tagStore.userTags.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                        tagStore.addUserTag(trimmed)
                        newTag = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.appGreenDark)
            }
            .padding(.top, 8)
            Spacer()
        }
        .padding()
        .frame(width: 340, height: 480)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.appWhite)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
        .alert("Delete Tag?", isPresented: Binding(
            get: { tagToDelete != nil },
            set: { if !$0 { tagToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let tagId = tagToDelete {
                    tagStore.removeUserTag(withId: tagId)
                }
                tagToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                tagToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this tag?")
        }
    }
}

struct TagManagementView_Previews: PreviewProvider {
    static var previews: some View {
        TagManagementView(
            settingsPage: .constant(.sectionControls)
        )
        .environmentObject(TagStore()) // Add this line
    }
}
