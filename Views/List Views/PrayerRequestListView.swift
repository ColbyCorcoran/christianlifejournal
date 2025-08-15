//
//  PrayerRequestListView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/11/25.
//

import SwiftUI
import SwiftData

struct PrayerRequestListView: View {
    @EnvironmentObject var prayerRequestStore: PrayerRequestStore
    @EnvironmentObject var prayerCategoryStore: PrayerCategoryStore
    @EnvironmentObject var tagStore: TagStore
    
    @State private var searchText = ""
    @State private var selectedFilter: PrayerFilter = .all
    @State private var selectedCategoryID: UUID? = nil
    @State private var showAddSheet = false
    @State private var showFilterSheet = false
    
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
            // Prayer Requests List
            if filteredRequests.isEmpty {
                // Empty State
                VStack(spacing: 16) {
                    Spacer()
                    
                    Image(systemName: searchText.isEmpty ? "heart" : "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text(emptyStateTitle)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(emptyStateSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
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
            } else {
                // Requests List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredRequests, id: \.id) { request in
                            NavigationLink(value: DashboardNav.prayerRequest(request.id)) {
                                PrayerRequestRowView(request: request)
                                    .environmentObject(prayerCategoryStore)
                                    .environmentObject(tagStore)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .padding(.bottom, 120) // Add padding for search bar
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appWhite)
            }
            
            // Search and Filter Bar (Fixed at bottom)
            VStack(spacing: 0) {
                Divider()
                
                VStack(spacing: 12) {
                    // Filter Controls
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
            AddPrayerRequestView()
                .environmentObject(prayerRequestStore)
                .environmentObject(prayerCategoryStore)
                .environmentObject(tagStore)
        }
        .onAppear {
            prayerRequestStore.refresh()
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
