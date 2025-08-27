//
//  TagPickerSheet.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/14/25.
//

import SwiftUI

struct TagPickerSheet: View {
    @Binding var selectedTagIDs: Set<UUID>
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tagStore: TagStore
    
    @State private var searchText = ""
    @State private var newTagName = ""
    @State private var showingAddTag = false
    @State private var temporarySelectedTagIDs: Set<UUID> = []
    
    private var filteredTags: [Tag] {
        let allTags = tagStore.userTags
        if searchText.isEmpty {
            return allTags.sorted { $0.name < $1.name }
        } else {
            return allTags
                .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.name < $1.name }
        }
    }
    
    private func toggleTag(_ tag: Tag) {
        if temporarySelectedTagIDs.contains(tag.id) {
            temporarySelectedTagIDs.remove(tag.id)
        } else {
            temporarySelectedTagIDs.insert(tag.id)
        }
    }
    
    private func applySelection() {
        selectedTagIDs = temporarySelectedTagIDs
        dismiss()
    }
    
    private func cancelSelection() {
        dismiss()
    }
    
    private func addNewTag() {
        guard !newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let trimmedName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if tag already exists
        if !tagStore.userTags.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            tagStore.addUserTag(trimmedName)
            
            // Find the newly added tag and select it temporarily
            if let newTag = tagStore.userTags.first(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
                temporarySelectedTagIDs.insert(newTag.id)
            }
            
            newTagName = ""
            showingAddTag = false
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Find Tags")
                        .font(.headline)
                        .foregroundColor(.appGreenDark)
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search tags...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appGreenDark.opacity(0.3), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.appGreenPale.opacity(0.1))
                            )
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                
                // Tags list
                if !filteredTags.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Available Tags")
                            .font(.headline)
                            .foregroundColor(.appGreenDark)
                            .padding(.horizontal, 20)
                        
                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(filteredTags, id: \.id) { tag in
                                    Button(action: { toggleTag(tag) }) {
                                        HStack {
                                            Image(systemName: temporarySelectedTagIDs.contains(tag.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(temporarySelectedTagIDs.contains(tag.id) ? .appGreenDark : .gray)
                                                .font(.title3)
                                            
                                            Text(tag.name)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(temporarySelectedTagIDs.contains(tag.id) ? Color.appGreenPale.opacity(0.3) : Color.clear)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
                } else if !searchText.isEmpty {
                    // No search results
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("No tags found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Try a different search term or add a new tag")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer()
                
                // Add new tag section
                VStack(alignment: .leading, spacing: 12) {
                    
                        Text("Add New Tag")
                            .font(.headline)
                            .foregroundColor(.appGreenDark)
                        
                        HStack {
                            TextField("Tag name", text: $newTagName)
                                .textFieldStyle(.plain)
                                .onSubmit {
                                    addNewTag()
                                }
                            
                            Button("Add") {
                                addNewTag()
                            }
                            .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .foregroundColor(.appGreenDark)
                            .fontWeight(.medium)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.appGreenDark, lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.appGreenPale.opacity(0.1))
                                )
                        )
                    
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.appWhite.ignoresSafeArea())
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        cancelSelection()
                    }
                    .foregroundColor(.appGreenDark)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applySelection()
                    }
                    .foregroundColor(.appGreenDark)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Initialize temporary selection with current selection
                temporarySelectedTagIDs = selectedTagIDs
                
                // Focus add tag if no tags exist
                if tagStore.userTags.isEmpty {
                    showingAddTag = true
                }
            }
        }
    }
}

// MARK: - Preview

struct TagPickerSheet_Previews: PreviewProvider {
    static var previews: some View {
        TagPickerSheet(selectedTagIDs: .constant(Set()))
            .environmentObject(TagPickerPreviewStore())
    }
}

// MARK: - Mock Preview Store
class TagPickerPreviewStore: ObservableObject {
    @Published var userTags: [Tag] = [
        Tag(name: "Worship", type: .user),
        Tag(name: "Prayer", type: .user),
        Tag(name: "Faith", type: .user),
        Tag(name: "Community", type: .user)
    ]
    
    func addTag(_ name: String) -> Tag {
        let newTag = Tag(name: name, type: .user)
        userTags.append(newTag)
        return newTag
    }
    
    func removeTag(withId id: UUID) {
        userTags.removeAll { $0.id == id }
    }
    
    func updateTag(withId id: UUID, newName: String) {
        if let index = userTags.firstIndex(where: { $0.id == id }) {
            userTags[index].name = newName
        }
    }
}
