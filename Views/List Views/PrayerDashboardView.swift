//
//  PrayerDashboardView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/11/25.
//

import SwiftUI
import SwiftData

struct PrayerDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var prayerCategoryStore: PrayerCategoryStore
    @EnvironmentObject var prayerRequestStore: PrayerRequestStore
    
    // Sheet states for add forms only
    @State private var showAddPrayerRequest = false
    @State private var showAddPrayerJournal = false
    @State private var showPrayerTypeSelection = false
    
    // Search functionality
    @State private var searchText = ""
    @State private var showSearchResults = false
    
    // Prayer journal query
    @Query(
        filter: #Predicate<JournalEntry> { entry in
            entry.section == "Prayer Journal"
        },
        sort: \JournalEntry.date,
        order: .reverse
    ) var prayerJournalEntries: [JournalEntry]
    
    // Filtered prayer requests based on search
    var filteredPrayerRequests: [PrayerRequest] {
        guard !searchText.isEmpty else { return [] }
        return prayerRequestStore.prayerRequests.filter { request in
            request.title.localizedCaseInsensitiveContains(searchText) ||
            request.requestDescription.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // Filtered prayer journal entries based on search
    var filteredPrayerJournalEntries: [JournalEntry] {
        guard !searchText.isEmpty else { return [] }
        return prayerJournalEntries.filter { entry in
            entry.title.localizedCaseInsensitiveContains(searchText) ||
            entry.bodyText?.localizedCaseInsensitiveContains(searchText) == true ||
            entry.notes?.localizedCaseInsensitiveContains(searchText) == true
        }
    }
    
    // Combined search results indicator
    var hasSearchResults: Bool {
        !searchText.isEmpty && (!filteredPrayerRequests.isEmpty || !filteredPrayerJournalEntries.isEmpty)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            ZStack {
                Color.appWhite.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "hands.and.sparkles.fill")
                                    .font(.title2)
                                    .foregroundColor(.appGreenDark)
                                Text("Prayer Center")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.appGreenDark)
                            }
                            
                            Text("Manage your prayer requests and journal entries")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        // Content based on search state
                        if !searchText.isEmpty {
                            if hasSearchResults {
                                searchResultsSection
                            } else {
                                searchEmptyStateSection
                            }
                        } else {
                            // Statistics Cards
                            statisticsSection(store: prayerRequestStore)
                            
                            // Navigation Cards
                            navigationCardsSection
                        }
                        
                        Spacer(minLength: 120) // Space for bottom search bar
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Fixed bottom search section
            VStack(spacing: 0) {
                Divider()
                
                VStack(spacing: 12) {
                    // Search bar with add button
                    HStack(spacing: 12) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search requests and entries...", text: $searchText)
                                .textFieldStyle(.plain)
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.appGreenDark.opacity(searchText.isEmpty ? 0.2 : 0.4), lineWidth: 1)
                                )
                        )
                        
                        // Add button
                        Button(action: {
                            showPrayerTypeSelection = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.appGreenDark))
                        }
                        .accessibilityLabel("Add Prayer Entry")
                    }
                }
                .padding()
                .background(Color.appWhite)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
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
        .sheet(isPresented: $showAddPrayerRequest) {
            AddPrayerRequestView()
                .environmentObject(prayerRequestStore)
                .environmentObject(prayerCategoryStore)
                .environmentObject(tagStore)
        }
        .sheet(isPresented: $showAddPrayerJournal) {
            AddEntryView(section: .prayerJournal)
                .environmentObject(tagStore)
        }
        .sheet(isPresented: $showPrayerTypeSelection) {
            PrayerEntryTypeSelectionSheet(
                isPresented: $showPrayerTypeSelection,
                showAddPrayerRequest: $showAddPrayerRequest,
                showAddPrayerJournal: $showAddPrayerJournal
            )
        }
    }
    
    // MARK: - Search Results Section
    
    @ViewBuilder
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Prayer Requests Results
            if !filteredPrayerRequests.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.appGreenDark)
                        Text("Prayer Requests")
                            .font(.headline)
                            .foregroundColor(.appGreenDark)
                        Spacer()
                        Text("\(filteredPrayerRequests.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(filteredPrayerRequests.prefix(3), id: \.id) { request in
                        NavigationLink(value: DashboardNav.prayerRequest(request.id)) {
                            PrayerSearchResultRow(
                                title: request.title,
                                subtitle: request.requestDescription,
                                icon: "heart.fill",
                                date: request.dateAdded
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if filteredPrayerRequests.count > 3 {
                        NavigationLink(value: DashboardNav.prayerRequests) {
                            Text("View all \(filteredPrayerRequests.count) prayer requests")
                                .font(.caption)
                                .foregroundColor(.appGreenDark)
                                .padding(.leading, 8)
                        }
                    }
                }
            }
            
            // Prayer Journal Results
            if !filteredPrayerJournalEntries.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "book.pages.fill")
                            .foregroundColor(.appGreenDark)
                        Text("Prayer Journal")
                            .font(.headline)
                            .foregroundColor(.appGreenDark)
                        Spacer()
                        Text("\(filteredPrayerJournalEntries.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(filteredPrayerJournalEntries.prefix(3), id: \.id) { entry in
                        NavigationLink(value: DashboardNav.entry(entry.id)) {
                            PrayerSearchResultRow(
                                title: entry.title,
                                subtitle: entry.bodyText ?? entry.notes ?? "",
                                icon: "book.pages.fill",
                                date: entry.date
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if filteredPrayerJournalEntries.count > 3 {
                        NavigationLink(value: DashboardNav.prayerJournal) {
                            Text("View all \(filteredPrayerJournalEntries.count) journal entries")
                                .font(.caption)
                                .foregroundColor(.appGreenDark)
                                .padding(.leading, 8)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Search Empty State
    
    @ViewBuilder
    private var searchEmptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No Results")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Try adjusting your search terms")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Navigation Cards Section
    
    @ViewBuilder
    private var navigationCardsSection: some View {
        VStack(spacing: 16) {
            // Prayer Requests Card
            NavigationLink(value: DashboardNav.prayerRequests) {
                NavigationCardView(
                    title: "Prayer Requests",
                    subtitle: prayerRequestStore.totalActiveRequests == 1 ? "1 active request" : "\(prayerRequestStore.totalActiveRequests) active requests",
                    icon: "heart.fill"
                )
            }
            .buttonStyle(.plain)
            
            // Prayer Journal Card
            NavigationLink(value: DashboardNav.prayerJournal) {
                NavigationCardView(
                    title: "Prayer Journal",
                    subtitle: prayerJournalEntries.count == 1 ? "1 journal entry" : "\(prayerJournalEntries.count) journal entries",
                    icon: "book.pages.fill"
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Statistics Section
    
    @ViewBuilder
    private func statisticsSection(store: PrayerRequestStore) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.appGreenDark)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                // Active Requests Stat
                StatCard(
                    title: "Active",
                    value: "\(store.totalActiveRequests)",
                    subtitle: store.totalActiveRequests == 1 ? "request" : "requests",
                    color: .appGreenDark
                )
                
                // Recently Answered Stat
                StatCard(
                    title: "Answered",
                    value: "\(store.recentlyAnsweredCount)",
                    subtitle: "this month",
                    color: .appGreenMedium
                )
                
                // Journal Entries Stat
                let thisMonthEntries = prayerJournalEntries.filter { entry in
                    Calendar.current.isDate(entry.date, equalTo: Date(), toGranularity: .month)
                }.count
                
                StatCard(
                    title: "Journals",
                    value: "\(thisMonthEntries)",
                    subtitle: "this month",
                    color: .appGreenLight
                )
            }
            .padding(.horizontal)
        }
    }
    
}

// MARK: - Supporting Views

struct NavigationCardView: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.appGreenDark)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}


// MARK: - Navigation Support

enum PrayerNavigationDestination: Hashable {
    case prayerRequests
    case prayerJournal
}

// MARK: - Prayer Entry Type Selection Sheet

struct PrayerEntryTypeSelectionSheet: View {
    @Binding var isPresented: Bool
    @Binding var showAddPrayerRequest: Bool
    @Binding var showAddPrayerJournal: Bool
    
    private var entryTypes: [(title: String, subtitle: String, icon: String, action: () -> Void)] {
        [
            (
                title: "Prayer Request",
                subtitle: "Track prayer requests and answered prayers",
                icon: "heart.fill",
                action: {
                    showAddPrayerRequest = true
                    isPresented = false
                }
            ),
            (
                title: "Prayer Journal Entry",
                subtitle: "Document prayer thoughts and spiritual insights",
                icon: "book.pages.fill",
                action: {
                    showAddPrayerJournal = true
                    isPresented = false
                }
            )
        ]
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.appGreenDark)
                            .font(.title3)
                        Text("Add Prayer Entry")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.appGreenDark)
                    }
                    
                    Text("Choose the type of prayer entry to create")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.appGreenPale.opacity(0.1))
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            
            Section("Entry Types") {
                ForEach(entryTypes.indices, id: \.self) { index in
                    let entryType = entryTypes[index]
                    Button(action: entryType.action) {
                        HStack {
                            Image(systemName: entryType.icon)
                                .foregroundColor(.appGreenDark)
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 24, height: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entryType.title)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text(entryType.subtitle)
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
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
        .listSectionSpacing(.compact)
        .presentationDetents([.height(280), .medium])
        .presentationDragIndicator(.visible)
        
    }
}

// MARK: - Prayer Search Result Row

struct PrayerSearchResultRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let date: Date
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.appGreenDark)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title.isEmpty ? "Untitled" : title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(formattedDate(date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: date))"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Preview

struct PrayerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrayerDashboardView()
                .environmentObject(previewTagStore)
                .environmentObject(previewPrayerRequestStore)
                .environmentObject(previewPrayerCategoryStore)
        }
    }
}

struct PrayerEntryTypeSelectionSheet_Previews: PreviewProvider {
    static var previews: some View {
        PrayerEntryTypeSelectionSheet(
            isPresented: .constant(true),
            showAddPrayerRequest: .constant(false),
            showAddPrayerJournal: .constant(false)
        )
    }
}
