//
//  BinderDashboardView.swift
//  Christian Life Journal
//
//  Dashboard for managing and viewing binders
//

import SwiftUI
import SwiftData

struct BinderDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var binderStore: BinderStore
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var speakerStore: SpeakerStore
    @EnvironmentObject var memorizationSettings: MemorizationSettings
    @EnvironmentObject var prayerCategoryStore: PrayerCategoryStore
    @EnvironmentObject var prayerRequestStore: PrayerRequestStore
    @State private var showCreateBinder = false
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    
    var filteredBinders: [Binder] {
        if searchText.isEmpty {
            return binderStore.binders
        } else {
            let lowercasedSearch = searchText.lowercased()
            return binderStore.binders.filter { binder in
                binder.name.lowercased().contains(lowercasedSearch) ||
                (binder.binderDescription?.lowercased().contains(lowercasedSearch) ?? false)
            }
        }
    }
    
    var body: some View {
            ZStack {
                Color.appWhite.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Binders List
                        if binderStore.binders.isEmpty {
                            emptyStateView
                        } else if filteredBinders.isEmpty {
                            noSearchResultsView
                        } else {
                            bindersListView
                        }
                        
                        Spacer(minLength: 80) // Extra space for floating button
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Bottom UI - Search and Add Button
                VStack {
                    Spacer()
                    HStack {
                        // Search Bar (only show when there are binders)
                        if !binderStore.binders.isEmpty {
                            searchBarSection
                        }
                        
                        Spacer()
                        
                        // Add Button
                        Button(action: {
                            showCreateBinder = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.appGreenDark))
                                .shadow(radius: 3)
                        }
                        .accessibilityLabel("Create New Binder")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
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
        .sheet(isPresented: $showCreateBinder) {
            CreateBinderView()
                .environmentObject(binderStore)
        }
        .onAppear {
            binderStore.refresh()
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "books.vertical.fill")
                    .font(.title2)
                    .foregroundColor(.appGreenDark)
                Text("Binders")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.appGreenDark)
            }
            
            Text("Organize your entries into collections for easy access")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var searchBarSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.appGreenDark)
                .font(.system(size: 16, weight: .medium))
            
            TextField("Search binders...", text: $searchText)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .font(.body)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray.opacity(0.6))
                        .font(.system(size: 14))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    private var bindersListView: some View {
        LazyVStack(spacing: 16) {
            ForEach(filteredBinders, id: \.id) { binder in
                NavigationLink(destination: BinderContentsView(binder: binder)
                    .environmentObject(binderStore)
                    .environmentObject(tagStore)
                    .environmentObject(speakerStore)
                    .environmentObject(memorizationSettings)
                    .environmentObject(prayerCategoryStore)
                    .environmentObject(prayerRequestStore)) {
                    BinderCardContent(binder: binder)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundColor(.appGreenMedium.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Binders Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.appGreenDark)
                
                Text("Create your first binder to start organizing your entries into collections")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .frame(maxHeight: .infinity)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var noSearchResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundColor(.appGreenMedium.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Binders Found")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.appGreenDark)
                
                Text("No binders match your search")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button(action: { searchText = "" }) {
                Text("Clear Search")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appGreenDark)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appGreenDark.opacity(0.3), lineWidth: 1)
                            .background(Color.appGreenPale.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxHeight: .infinity)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Binder Card Component

struct BinderCardContent: View {
    let binder: Binder
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Vertical color strip
            Rectangle()
                .fill(binder.color)
                .frame(width: 4)
                .padding(.trailing, 12)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                    // Title and entry count
                    HStack {
                        Text(binder.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Text("\(binder.totalEntryCount)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.appGreenDark)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.appGreenPale.opacity(0.3))
                            )
                    }
                    
                    // Description (if available)
                    if let description = binder.binderDescription, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Date created
                    Text("Created \(binder.formattedDateCreated)")
                        .font(.caption)
                        .foregroundColor(.secondary)
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

// MARK: - Preview

struct BinderDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MockBinderDashboardView()
        }
    }
}

// Temporary mock view for preview testing
struct MockBinderDashboardView: View {
    var body: some View {
        ZStack {
            Color.appWhite.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Mock Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .font(.title2)
                                .foregroundColor(.appGreenDark)
                            
                            Text("My Binders")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.appGreenDark)
                            
                            Spacer()
                            
                            Text("3")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.appGreenMedium)
                        }
                        
                        Text("Organize your entries into collections for easy access")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appGreenPale.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appGreenDark.opacity(0.2), lineWidth: 1)
                            )
                    )
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Binders")
        .navigationBarTitleDisplayMode(.large)
    }
}
