//
//  PrayerCategoryManagementSettingsView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/14/25.
//

import SwiftUI
import SwiftData

struct PrayerCategoryManagementSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [PrayerCategory]
    @State private var newCategory: String = ""
    @State private var editingCategoryId: UUID? = nil
    @State private var editedCategory: String = ""
    @State private var categoryToDelete: UUID? = nil

    var body: some View {
        List {
            // Info Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About Categories")
                        .font(.headline)
                        .foregroundColor(.appGreenDark)
                    
                    Text("Categories help you organize prayer requests by topic. You can edit or delete any category, including the default ones.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
            
            // Add New Category Section
            Section("Add New Category") {
                HStack {
                    TextField("Category name...", text: $newCategory)
                    Button("Add") {
                        let trimmed = newCategory.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty && !categories.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                            let newCategoryModel = PrayerCategory(name: trimmed)
                            modelContext.insert(newCategoryModel)
                            try? modelContext.save()
                            newCategory = ""
                        }
                    }
                    .disabled(newCategory.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundColor(.appGreenDark)
                }
            }
            
            // Your Categories Section
            Section("Your Categories") {
                if categories.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "folder")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                        Text("No categories yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Create your first category above")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(categories, id: \.id) { category in
                        categoryRow(for: category)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    categoryToDelete = category.id
                                }
                                
                                Button("Edit") {
                                    editedCategory = category.name
                                    editingCategoryId = category.id
                                }
                                .tint(.appGreenDark)
                            }
                    }
                }
            }
        }
        .navigationTitle("Manage Prayer Categories")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Category?", isPresented: Binding(
            get: { categoryToDelete != nil },
            set: { if !$0 { categoryToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let categoryId = categoryToDelete {
                    if let categoryToDelete = categories.first(where: { $0.id == categoryId }) {
                        modelContext.delete(categoryToDelete)
                        try? modelContext.save()
                    }
                }
                categoryToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                categoryToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this category? Prayer requests using this category will become uncategorized.")
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func categoryRow(for category: PrayerCategory) -> some View {
        if editingCategoryId == category.id {
            HStack {
                TextField("Category name", text: $editedCategory)
                    .textFieldStyle(.roundedBorder)
                
                Button("Save") {
                    if !editedCategory.trimmingCharacters(in: .whitespaces).isEmpty {
                        category.name = editedCategory
                        try? modelContext.save()
                    }
                    editingCategoryId = nil
                    editedCategory = ""
                }
                .disabled(editedCategory.trimmingCharacters(in: .whitespaces).isEmpty)
                .foregroundColor(.appGreenDark)
                
                Button("Cancel") {
                    editingCategoryId = nil
                    editedCategory = ""
                }
                .foregroundColor(.secondary)
            }
        } else {
            Label(category.name, systemImage: "folder")
        }
    }
}

// MARK: - Preview

struct PrayerCategoryManagementSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrayerCategoryManagementSettingsView()
                .environmentObject(previewPrayerCategoryStore)
                .modelContainer(previewContainer)
        }
    }
}