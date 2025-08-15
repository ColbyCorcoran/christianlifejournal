//
//  TagManagementSettingsView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/14/25.
//

import SwiftUI

struct TagManagementSettingsView: View {
    @EnvironmentObject var tagStore: TagStore
    @State private var newTag: String = ""
    @State private var editingTagId: UUID? = nil
    @State private var editedTag: String = ""
    @State private var tagToDelete: UUID? = nil

    var body: some View {
        List {
            // Info Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About Tags")
                        .font(.headline)
                        .foregroundColor(.appGreenDark)
                    
                    Text("Auto-applied Bible book and section tags are used for filtering but only your custom tags are shown here.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
            
            // Add New Tag Section
            Section("Add New Tag") {
                HStack {
                    TextField("Tag name...", text: $newTag)
                    Button("Add") {
                        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty && !tagStore.userTags.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                            tagStore.addUserTag(trimmed)
                            newTag = ""
                        }
                    }
                    .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundColor(.appGreenDark)
                }
            }
            
            // Your Tags Section
            Section("Your Tags") {
                if tagStore.userTags.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tag")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                        Text("No custom tags yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Create your first tag above")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(tagStore.userTags, id: \.id) { tag in
                        tagRow(for: tag)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    tagToDelete = tag.id
                                }
                                
                                Button("Edit") {
                                    editedTag = tag.name
                                    editingTagId = tag.id
                                }
                                .tint(.appGreenDark)
                            }
                    }
                }
            }
        }
        .navigationTitle("Manage Tags")
        .navigationBarTitleDisplayMode(.inline)
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
            Text("Are you sure you want to delete this tag? This action cannot be undone.")
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func tagRow(for tag: Tag) -> some View {
        if editingTagId == tag.id {
            HStack {
                TextField("Tag name", text: $editedTag)
                    .textFieldStyle(.roundedBorder)
                
                Button("Save") {
                    if !editedTag.trimmingCharacters(in: .whitespaces).isEmpty {
                        tagStore.updateUserTag(withId: tag.id, newName: editedTag)
                    }
                    editingTagId = nil
                    editedTag = ""
                }
                .disabled(editedTag.trimmingCharacters(in: .whitespaces).isEmpty)
                .foregroundColor(.appGreenDark)
                
                Button("Cancel") {
                    editingTagId = nil
                    editedTag = ""
                }
                .foregroundColor(.secondary)
            }
        } else {
            Label(tag.name, systemImage: "tag")
        }
    }
}

// MARK: - Preview

struct TagManagementSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TagManagementSettingsView()
                .environmentObject(previewTagStore)
                .modelContainer(previewContainer)
        }
    }
}