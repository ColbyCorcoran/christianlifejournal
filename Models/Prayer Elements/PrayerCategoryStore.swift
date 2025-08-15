//
//  PrayerCategoryStore.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/11/25.
//

import SwiftUI
import SwiftData

class PrayerCategoryStore: ObservableObject {
    @Published var categories: [PrayerCategory] = []
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Only refresh if not in preview mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            refresh()
            initializeDefaultCategoriesIfNeeded()
        }
    }
    
    // MARK: - Data Management
    
    func refresh() {
        let descriptor = FetchDescriptor<PrayerCategory>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            categories = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching prayer categories: \(error)")
            categories = []
        }
    }
    
    private func initializeDefaultCategoriesIfNeeded() {
        // Only add default categories if no categories exist
        if categories.isEmpty {
            for categoryName in PrayerCategory.defaultCategories {
                addCategory(categoryName)
            }
        }
    }
    
    // MARK: - CRUD Operations
    
    func addCategory(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Check if category with this name already exists (case insensitive)
        let existingCategory = categories.first { 
            $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame 
        }
        guard existingCategory == nil else { return }
        
        let newCategory = PrayerCategory(name: trimmedName)
        modelContext.insert(newCategory)
        
        do {
            try modelContext.save()
            refresh()
        } catch {
            print("Error adding prayer category: \(error)")
        }
    }
    
    func updateCategory(withId id: UUID, newName: String) {
        guard let category = categories.first(where: { $0.id == id }) else { return }
        
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Check if another category with this name already exists
        let existingCategory = categories.first { 
            $0.id != id && $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame 
        }
        guard existingCategory == nil else { return }
        
        category.name = trimmedName
        
        do {
            try modelContext.save()
            refresh()
        } catch {
            print("Error updating prayer category: \(error)")
        }
    }
    
    func removeCategory(withId id: UUID) {
        guard let category = categories.first(where: { $0.id == id }) else { return }
        
        modelContext.delete(category)
        
        do {
            try modelContext.save()
            refresh()
        } catch {
            print("Error removing prayer category: \(error)")
        }
    }
    
    func removeAllCategories() {
        for category in categories {
            modelContext.delete(category)
        }
        
        do {
            try modelContext.save()
            refresh()
        } catch {
            print("Error removing all prayer categories: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    func categoryName(for id: UUID?) -> String? {
        guard let id = id else { return nil }
        return categories.first(where: { $0.id == id })?.name
    }
    
    func category(for id: UUID?) -> PrayerCategory? {
        guard let id = id else { return nil }
        return categories.first(where: { $0.id == id })
    }
}

