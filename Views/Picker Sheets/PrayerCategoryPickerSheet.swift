//
//  PrayerCategoryPickerSheet.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/14/25.
//

import SwiftUI

struct PrayerCategoryPickerSheet: View {
    @Binding var selectedCategoryIDs: Set<UUID>
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var prayerCategoryStore: PrayerCategoryStore
    
    @State private var searchText = ""
    @State private var newCategoryName = ""
    @State private var showingAddCategory = false
    
    private var filteredCategories: [PrayerCategory] {
        let allCategories = prayerCategoryStore.categories
        if searchText.isEmpty {
            return allCategories.sorted { $0.name < $1.name }
        } else {
            return allCategories
                .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.name < $1.name }
        }
    }
    
    private func toggleCategory(_ category: PrayerCategory) {
        if selectedCategoryIDs.contains(category.id) {
            selectedCategoryIDs.remove(category.id)
        } else {
            selectedCategoryIDs.insert(category.id)
        }
    }
    
    private func addNewCategory() {
        guard !newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if category already exists
        if !prayerCategoryStore.categories.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            prayerCategoryStore.addCategory(trimmedName)
            
            // Find the newly added category and select it
            if let newCategory = prayerCategoryStore.categories.first(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
                selectedCategoryIDs.insert(newCategory.id)
            }
            
            newCategoryName = ""
            showingAddCategory = false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
                // Search section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Find Categories")
                        .font(.headline)
                        .foregroundColor(.appGreenDark)
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search categories...", text: $searchText)
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
                
                // Categories list
                if !filteredCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Available Categories")
                            .font(.headline)
                            .foregroundColor(.appGreenDark)
                            .padding(.horizontal, 20)
                        
                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(filteredCategories, id: \.id) { category in
                                    Button(action: { toggleCategory(category) }) {
                                        HStack {
                                            Image(systemName: selectedCategoryIDs.contains(category.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedCategoryIDs.contains(category.id) ? .appGreenDark : .gray)
                                                .font(.title3)
                                            
                                            Text(category.name)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedCategoryIDs.contains(category.id) ? Color.appGreenLight.opacity(0.3) : Color.clear)
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
                        
                        Text("No categories found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Try a different search term or add a new category")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if prayerCategoryStore.categories.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "folder")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("No categories available")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Create categories in Settings or add one below to organize your prayer requests")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer()
                
                // Add new category section
                VStack(alignment: .leading, spacing: 12) {
                    
                        Text("Add New Category")
                            .font(.headline)
                            .foregroundColor(.appGreenDark)
                        
                        HStack {
                            TextField("Category name", text: $newCategoryName)
                                .textFieldStyle(.plain)
                                .onSubmit {
                                    addNewCategory()
                                }
                            
                            Button("Add") {
                                addNewCategory()
                            }
                            .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        .onAppear {
            // Focus add category if no categories exist
            if prayerCategoryStore.categories.isEmpty {
                showingAddCategory = true
            }
        }
    }
}

// MARK: - Preview

struct PrayerCategoryPickerSheet_Previews: PreviewProvider {
    static var previews: some View {
        PrayerCategoryPickerSheet(selectedCategoryIDs: .constant(Set()))
            .environmentObject(PrayerCategoryPickerPreviewStore())
    }
}

// MARK: - Mock Preview Store
class PrayerCategoryPickerPreviewStore: ObservableObject {
    @Published var categories: [PrayerCategory] = [
        PrayerCategory(name: "Family"),
        PrayerCategory(name: "Health"),
        PrayerCategory(name: "Work"),
        PrayerCategory(name: "Friends")
    ]
    
    func addCategory(_ name: String) {
        let newCategory = PrayerCategory(name: name)
        categories.append(newCategory)
    }
    
    func removeCategory(withId id: UUID) {
        categories.removeAll { $0.id == id }
    }
    
    func updateCategory(withId id: UUID, newName: String) {
        if let index = categories.firstIndex(where: { $0.id == id }) {
            categories[index].name = newName
        }
    }
}
