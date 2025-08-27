//
//  PrayerRequestListView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/11/25.
//

import SwiftUI
import SwiftData

struct PrayerRequestListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var prayerRequestStore: PrayerRequestStore
    @EnvironmentObject var prayerCategoryStore: PrayerCategoryStore
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var binderStore: BinderStore
    
    @State private var searchText = ""
    @State private var selectedFilter: PrayerFilter = .all
    @State private var selectedCategoryID: UUID? = nil
    @State private var showAddSheet = false
    @State private var showFilterSheet = false
    
    // Multi-select state
    @State private var isEditing = false
    @State private var selectedRequests: Set<PrayerRequest> = []
    @State private var showBulkActions = false
    @State private var showDeleteAlert = false
    
    // Bulk action state
    @State private var showTagPicker = false
    @State private var showCategoryPicker = false
    @State private var showScripturePicker = false
    @State private var showBulkBinderPicker = false
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var selectedCategoryIDs: Set<UUID> = []
    @State private var selectedScripturePassages: [ScripturePassageSelection] = []
    @State private var showSuccessAlert = false
    @State private var successMessage = ""
    
    var filteredRequests: [PrayerRequest] {
        var requests = prayerRequestStore.prayerRequests
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .active:
            requests = requests.filter { !$0.isAnswered }
        case .answered:
            requests = requests.filter { $0.isAnswered }
        }
        
        // Apply category filter
        if let categoryID = selectedCategoryID {
            requests = requests.filter { $0.categoryIDs.contains(categoryID) }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            requests = requests.filter { request in
                request.title.localizedCaseInsensitiveContains(searchText) ||
                request.requestDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return requests
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .font(.title2)
                                .foregroundColor(.appGreenDark)
                            Text("Prayer Requests")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.appGreenDark)
                        }
                        
                        Text("Track prayer requests and answered prayers")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Content
                    if filteredRequests.isEmpty {
                        HStack {
                            Spacer()
                            emptyStateView
                            Spacer()
                        }
                    } else {
                        requestsListContent
                    }
                    
                    Spacer(minLength: 120) // Space for search bar
                }
            }
            .background(Color.appWhite)
            
            // Search and Filter Bar (Fixed at bottom)
            searchAndFilterBar
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .medium))
                            Text("Back")
                        }
                    }
                    .foregroundColor(.appGreenDark)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    HStack {
                        let selectedCount = selectedRequests.count
                        if selectedCount > 0 {
                            Button("Actions (\(selectedCount))") {
                                showBulkActions = true
                            }
                            .foregroundColor(.appGreenDark)
                        }
                        
                        Button("Done") {
                            isEditing = false
                            selectedRequests.removeAll()
                            showBulkActions = false
                        }
                    }
                } else {
                    Button("Select") { isEditing = true }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddPrayerRequestView()
                .environmentObject(prayerRequestStore)
                .environmentObject(prayerCategoryStore)
                .environmentObject(tagStore)
        }
        .sheet(isPresented: $showBulkActions) {
            BulkActionsSheet(
                selectedCount: selectedRequests.count,
                isPresented: $showBulkActions,
                onAddTags: { showTagPicker = true },
                onAddCategories: { showCategoryPicker = true },
                onAddScripture: { showScripturePicker = true },
                onAddToBinders: { showBulkBinderPicker = true },
                onDelete: { showDeleteAlert = true }
            )
        }
        .alert("Delete Prayer Requests?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                // Delete all selected requests
                for request in selectedRequests {
                    modelContext.delete(request)
                }
                
                do {
                    try modelContext.save()
                    prayerRequestStore.refresh()
                    selectedRequests.removeAll()
                    isEditing = false
                } catch {
                    print("Error deleting prayer requests: \(error)")
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete the selected \(selectedRequests.count) prayer request\(selectedRequests.count == 1 ? "" : "s")? This action cannot be undone.")
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") { }
        } message: {
            Text(successMessage)
        }
        .sheet(isPresented: $showTagPicker) {
            NavigationStack {
                VStack {
                    // Custom navigation bar
                    HStack {
                        Button("Cancel") {
                            selectedTagIDs.removeAll()
                            showTagPicker = false
                        }
                        .foregroundColor(.appGreenDark)
                        
                        Spacer()
                        
                        Text("Add Tags")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Apply") {
                            // Apply tags when Apply is pressed
                            if !selectedTagIDs.isEmpty {
                                for request in selectedRequests {
                                    var tagIDs = request.tagIDs
                                    tagIDs.append(contentsOf: selectedTagIDs.filter { !tagIDs.contains($0) })
                                    request.tagIDs = tagIDs
                                }
                                try? modelContext.save()
                                prayerRequestStore.refresh()
                                
                                // Show success message
                                let tagCount = selectedTagIDs.count
                                let requestCount = selectedRequests.count
                                let tagText = tagCount == 1 ? "tag" : "tags"
                                let requestText = requestCount == 1 ? "request" : "requests"
                                
                                successMessage = "Added \(tagCount) \(tagText) to \(requestCount) \(requestText)"
                                showSuccessAlert = true
                                
                                selectedTagIDs.removeAll()
                                selectedRequests.removeAll()
                                isEditing = false
                            }
                            showTagPicker = false
                        }
                        .disabled(selectedTagIDs.isEmpty)
                        .foregroundColor(selectedTagIDs.isEmpty ? .gray : .appGreenDark)
                    }
                    .padding()
                    
                    Divider()
                    
                    TagPickerSheet(selectedTagIDs: $selectedTagIDs)
                        .environmentObject(tagStore)
                }
                .background(Color.appWhite.ignoresSafeArea())
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCategoryPicker) {
            NavigationStack {
                VStack {
                    // Custom navigation bar
                    HStack {
                        Button("Cancel") {
                            selectedCategoryIDs.removeAll()
                            showCategoryPicker = false
                        }
                        .foregroundColor(.appGreenDark)
                        
                        Spacer()
                        
                        Text("Add Categories")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Apply") {
                            // Apply categories when Apply is pressed
                            if !selectedCategoryIDs.isEmpty {
                                for request in selectedRequests {
                                    var categoryIDs = request.categoryIDs
                                    categoryIDs.append(contentsOf: selectedCategoryIDs.filter { !categoryIDs.contains($0) })
                                    request.categoryIDs = categoryIDs
                                }
                                try? modelContext.save()
                                prayerRequestStore.refresh()
                                
                                // Show success message
                                let categoryCount = selectedCategoryIDs.count
                                let requestCount = selectedRequests.count
                                let categoryText = categoryCount == 1 ? "category" : "categories"
                                let requestText = requestCount == 1 ? "request" : "requests"
                                
                                successMessage = "Added \(categoryCount) \(categoryText) to \(requestCount) \(requestText)"
                                showSuccessAlert = true
                                
                                selectedCategoryIDs.removeAll()
                                selectedRequests.removeAll()
                                isEditing = false
                            }
                            showCategoryPicker = false
                        }
                        .disabled(selectedCategoryIDs.isEmpty)
                        .foregroundColor(selectedCategoryIDs.isEmpty ? .gray : .appGreenDark)
                    }
                    .padding()
                    
                    Divider()
                    
                    PrayerCategoryPickerSheet(selectedCategoryIDs: $selectedCategoryIDs)
                        .environmentObject(prayerCategoryStore)
                }
                .background(Color.appWhite.ignoresSafeArea())
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showScripturePicker) {
            NavigationStack {
                VStack {
                    // Custom navigation bar
                    HStack {
                        Button("Cancel") {
                            selectedScripturePassages.removeAll()
                            showScripturePicker = false
                        }
                        .foregroundColor(.appGreenDark)
                        
                        Spacer()
                        
                        Text("Add Scripture")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Apply") {
                            // Apply scripture when Apply is pressed
                            if !selectedScripturePassages.isEmpty {
                                // Convert selected passages to scripture text
                                let scriptureText = selectedScripturePassages.map { passage in
                                    let book = bibleBooks[passage.bookIndex]
                                    if passage.verse == passage.verseEnd {
                                        return "\(book.name) \(passage.chapter):\(passage.verse)"
                                    } else {
                                        return "\(book.name) \(passage.chapter):\(passage.verse)-\(passage.verseEnd)"
                                    }
                                }.joined(separator: "; ")
                                
                                // Add selected scripture to all selected requests
                                for request in selectedRequests {
                                    if request.scripture?.isEmpty ?? true {
                                        request.scripture = scriptureText
                                    } else {
                                        request.scripture = (request.scripture ?? "") + "; " + scriptureText
                                    }
                                }
                                try? modelContext.save()
                                prayerRequestStore.refresh()
                                
                                // Show success message
                                let passageCount = selectedScripturePassages.count
                                let requestCount = selectedRequests.count
                                let passageText = passageCount == 1 ? "scripture passage" : "scripture passages"
                                let requestText = requestCount == 1 ? "request" : "requests"
                                
                                successMessage = "Added \(passageCount) \(passageText) to \(requestCount) \(requestText)"
                                showSuccessAlert = true
                                
                                selectedScripturePassages.removeAll()
                                selectedRequests.removeAll()
                                isEditing = false
                            }
                            showScripturePicker = false
                        }
                        .disabled(selectedScripturePassages.isEmpty)
                        .foregroundColor(selectedScripturePassages.isEmpty ? .gray : .appGreenDark)
                    }
                    .padding()
                    
                    Divider()
                    
                    ScripturePickerSheet(selectedPassages: $selectedScripturePassages)
                }
                .background(Color.appWhite.ignoresSafeArea())
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBulkBinderPicker) {
            BulkBinderPickerSheet(
                selectedItems: .prayerRequests(Array(selectedRequests)),
                isPresented: $showBulkBinderPicker,
                onComplete: {
                    selectedRequests.removeAll()
                    isEditing = false
                }
            )
            .environmentObject(binderStore)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            prayerRequestStore.refresh()
            // Clear any stale selection state
            selectedRequests.removeAll()
            isEditing = false
            showBulkActions = false
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: searchText.isEmpty ? "heart" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.6))
            
            Text(emptyStateTitle)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if searchText.isEmpty && selectedFilter == .all {
                Button("Add Prayer Request") {
                    showAddSheet = true
                }
                .foregroundColor(.appGreenDark)
                .font(.headline)
                .padding(.top)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appWhite)
    }
    
    @ViewBuilder
    private var requestsListContent: some View {
        LazyVStack(spacing: 16) {
            ForEach(filteredRequests, id: \.id) { request in
                requestRowView(for: request)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func requestRowView(for request: PrayerRequest) -> some View {
        if isEditing {
            HStack {
                Image(systemName: selectedRequests.contains(request) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedRequests.contains(request) ? .appGreenDark : .gray)
                    .font(.title3)
                
                PrayerRequestRowView(request: request)
                    .environmentObject(prayerCategoryStore)
                    .environmentObject(tagStore)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if selectedRequests.contains(request) {
                    selectedRequests.remove(request)
                } else {
                    selectedRequests.insert(request)
                }
            }
        } else {
            NavigationLink(value: DashboardNav.prayerRequest(request.id)) {
                PrayerRequestRowView(request: request)
                    .environmentObject(prayerCategoryStore)
                    .environmentObject(tagStore)
                    .environmentObject(binderStore)
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    private var searchAndFilterBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(spacing: 12) {
                // Filter Controls
                filterControlsView
                
                // Search Bar with Add Button
                searchBarView
            }
            .padding()
            .background(Color.appWhite)
        }
    }
    
    @ViewBuilder
    private var filterControlsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Status Filters
                ForEach(PrayerFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
                
                // Category Filters
                if !prayerCategoryStore.categories.isEmpty {
                    Divider()
                        .frame(height: 20)
                    
                    FilterChip(
                        title: "All Categories",
                        isSelected: selectedCategoryID == nil,
                        action: { selectedCategoryID = nil }
                    )
                    
                    ForEach(prayerCategoryStore.categories, id: \.id) { category in
                        FilterChip(
                            title: category.name,
                            isSelected: selectedCategoryID == category.id,
                            action: { selectedCategoryID = category.id }
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var searchBarView: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search prayer requests...", text: $searchText)
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
            
            Button(action: {
                showAddSheet = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.appGreenDark))
                    .shadow(radius: 3)
            }
            .accessibilityLabel("Add Prayer Request")
        }
    }
    
    // MARK: - Helper Properties
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Results"
        } else {
            switch selectedFilter {
            case .all:
                return "No Prayer Requests"
            case .active:
                return "No Active Requests"
            case .answered:
                return "No Answered Prayers"
            }
        }
    }
    
    private var emptyStateSubtitle: String {
        if !searchText.isEmpty {
            return "Try adjusting your search or filters"
        } else {
            switch selectedFilter {
            case .all:
                return "Create your first prayer request to get started"
            case .active:
                return "All your prayer requests have been answered! Praise God!"
            case .answered:
                return "No answered prayers yet. Keep praying and trusting!"
            }
        }
    }
}

// MARK: - Supporting Views

struct PrayerRequestRowView: View {
    let request: PrayerRequest
    @EnvironmentObject var prayerCategoryStore: PrayerCategoryStore
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var binderStore: BinderStore
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status Icon
            Image(systemName: request.isAnswered ? "checkmark.circle.fill" : "clock.fill")
                .font(.title3)
                .foregroundColor(request.isAnswered ? .appGreenDark : .appGreenMedium)
                .frame(width: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title and Date
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(request.title)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        if !request.requestDescription.isEmpty {
                            Text(request.requestDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(request.formattedDateAdded)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if request.isAnswered {
                            Text("Answered")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.appGreenDark)
                        } else {
                            let days = request.daysSincePrayed
                            Text("\(days) \(days == 1 ? "day" : "days")")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Categories and Tags
                HStack {
                    // Display first few categories
                    let categoryNames = request.categoryIDs.prefix(2).compactMap { categoryID in
                        prayerCategoryStore.categoryName(for: categoryID)
                    }
                    
                    ForEach(categoryNames, id: \.self) { categoryName in
                        Text(categoryName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.appGreenLight.opacity(0.3))
                            )
                            .foregroundColor(.appGreenDark)
                    }
                    
                    if request.categoryIDs.count > 2 {
                        Text("+\(request.categoryIDs.count - 2)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Tags
                    let userTags = request.tagIDs.prefix(2).compactMap { tagID in
                        tagStore.userTags.first { $0.id == tagID }
                    }
                    
                    ForEach(userTags, id: \.id) { tag in
                        Text(tag.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.appGreenMedium.opacity(0.3))
                            )
                            .foregroundColor(.appGreenDark)
                    }
                    
                    if request.tagIDs.count > 2 {
                        Text("+\(request.tagIDs.count - 2)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Binder indicators
                    let requestBinders = binderStore.bindersContaining(prayerRequestID: request.id)
                    if !requestBinders.isEmpty {
                        let maxBinders = 1
                        let displayBinders = requestBinders.prefix(maxBinders)
                        
                        ForEach(Array(displayBinders), id: \.id) { binder in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(binder.color)
                                    .frame(width: 8, height: 8)
                                
                                Text(binder.name)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.appGreenPale.opacity(0.4))
                            )
                            .foregroundColor(.appGreenDark)
                        }
                        
                        if requestBinders.count > maxBinders {
                            Text("+\(requestBinders.count - maxBinders)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
        )
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.appGreenDark : Color.gray.opacity(0.1))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Enums

enum PrayerFilter: String, CaseIterable {
    case all = "all"
    case active = "active"
    case answered = "answered"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .active: return "Active"
        case .answered: return "Answered"
        }
    }
}

// MARK: - Bulk Actions Sheet

struct BulkActionsSheet: View {
    let selectedCount: Int
    @Binding var isPresented: Bool
    
    let onAddTags: () -> Void
    let onAddCategories: () -> Void
    let onAddScripture: () -> Void
    let onAddToBinders: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.appGreenDark)
                            .font(.title3)
                        Text("Bulk Actions")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.appGreenDark)
                    }
                    
                    Text("\(selectedCount) prayer request\(selectedCount == 1 ? "" : "s") selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 0)
            }
            .listRowBackground(Color.appGreenPale.opacity(0.1))
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            
            Section("Actions") {
                Button(action: {
                    onAddTags()
                    isPresented = false
                }) {
                    actionRowView(
                        icon: "tag.circle.fill",
                        title: "Add Tags",
                        subtitle: "Apply tags to all selected prayer requests"
                    )
                }
                
                Button(action: {
                    onAddCategories()
                    isPresented = false
                }) {
                    actionRowView(
                        icon: "folder.circle.fill",
                        title: "Add Categories",
                        subtitle: "Assign prayer categories to all selected requests"
                    )
                }
                
                Button(action: {
                    onAddScripture()
                    isPresented = false
                }) {
                    actionRowView(
                        icon: "book.circle.fill",
                        title: "Add Scripture",
                        subtitle: "Add scripture passages to all selected requests"
                    )
                }
                
                Button(action: {
                    onAddToBinders()
                    isPresented = false
                }) {
                    actionRowView(
                        icon: "books.vertical.circle.fill",
                        title: "Add to Binders",
                        subtitle: "Add all selected requests to binders"
                    )
                }
                
                Button(action: {
                    onDelete()
                    isPresented = false
                }) {
                    actionRowView(
                        icon: "trash",
                        title: "Delete",
                        subtitle: "Permanently remove all selected requests",
                        isDestructive: true
                    )
                }
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
        .listSectionSpacing(.compact)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder
    private func actionRowView(icon: String, title: String, subtitle: String, isDestructive: Bool = false) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isDestructive ? .red : .appGreenDark)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct PrayerRequestListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // NUCLEAR OPTION: Completely separate preview that avoids ALL SwiftData
            SwiftDataFreePreviewPrayerRequestListView()
        }
    }
}

// MARK: - SwiftData-Free Preview Implementation

struct SwiftDataFreePreviewPrayerRequestListView: View {
    @State private var searchText = ""
    @State private var selectedFilter: PrayerFilter = .all
    @State private var selectedCategoryID: UUID? = nil
    @State private var showAddSheet = false
    
    var body: some View {
        ZStack {
            Color.appWhite.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                
                
                
                // Empty State (always shown in preview to avoid SwiftData)
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: "heart")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("No Prayer Requests")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Create your first prayer request to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Add Prayer Request") {
                        showAddSheet = true
                    }
                    .foregroundColor(.appGreenDark)
                    .font(.headline)
                    .padding(.top)
                    
                    Spacer()
                }
                
                Divider()
                
                // Search and Filter Bar
                VStack(spacing: 12) {
                    // Filter Controls
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(PrayerFilter.allCases, id: \.self) { filter in
                                FilterChip(
                                    title: filter.displayName,
                                    isSelected: selectedFilter == filter,
                                    action: { selectedFilter = filter }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Search Bar with Add Button
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search prayer requests...", text: $searchText)
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
                        
                        Button(action: {
                            showAddSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.appGreenDark))
                                .shadow(radius: 3)
                        }
                        .accessibilityLabel("Add Prayer Request")
                    }
                    
                    
                }
                .padding()
                .background(Color.appWhite)
            }
        }
        .navigationTitle("Prayer Requests")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddSheet) {
            Text("Add Prayer Request Preview")
                .padding()
        }
    }
}
