//
//  JournalEntryDetailView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 6/20/25.
//

import SwiftUI
import SwiftData

struct JournalEntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let entry: JournalEntry
    let showBinderFunctionality: Bool
    
    init(entry: JournalEntry, showBinderFunctionality: Bool = true) {
        self.entry = entry
        self.showBinderFunctionality = showBinderFunctionality
    }
    
    @EnvironmentObject var speakerStore: SpeakerStore
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var memorizationSettings: MemorizationSettings
    @EnvironmentObject var prayerCategoryStore: PrayerCategoryStore
    @EnvironmentObject var prayerRequestStore: PrayerRequestStore
    @EnvironmentObject var binderStore: BinderStore
    
    @State private var showEditSheet = false
    @State private var showBinderContents = false
    @State private var showBinderSelector = false
    @State private var selectedBinder: Binder?
    
    // Parse scripture passages for chip display
    private var scripturePassages: [String] {
        guard let scripture = entry.scripture, !scripture.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        // Split by semicolon and clean up each passage
        return scripture.components(separatedBy: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    // Computed properties for binder context
    private var entryBinders: [Binder] {
        binderStore.bindersContaining(journalEntryID: entry.id)
    }
    
    private var isInBinders: Bool {
        !entryBinders.isEmpty
    }
    
    var body: some View {
        ZStack {
            Color.appWhite.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Entry Details Card with Date in Upper Right
                    VStack(alignment: .leading, spacing: 12) {
                        
                        HStack {
                            Text("Entry Details")
                                .font(.headline)
                                .foregroundColor(.appGreenDark)
                            
                            Spacer()
                            
                            Text(formattedDate(entry.date))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                        
                        // Title content
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.appGreenDark)
                            
                            Text(entry.title.isEmpty ? formattedDate(entry.date) : entry.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        
                        // Scripture Passages (if present)
                        scripturePassageSection
                        
                        // Speaker and Tags (if present)
                        speakerAndTagsSection
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    
                    // Notes and Reflections Card
                    if let notes = entry.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes & Reflections")
                                .font(.headline)
                                .foregroundColor(.appGreenDark)
                            
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.appGreenPale.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.appGreenDark.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Contextual binder icon - only show if entry is in binders and binder functionality is enabled
                    if showBinderFunctionality && isInBinders {
                        Button(action: {
                            handleBinderIconTap()
                        }) {
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.appGreenDark)
                        .accessibilityLabel(entryBinders.count == 1 ? "View Binder" : "View Binders")
                    }
                    
                    Button("Edit") {
                        showEditSheet = true
                    }
                    .foregroundColor(.appGreenDark)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            // FIXED: Remove tagStore and speakerStore parameters since they use @EnvironmentObject
            switch JournalSection(rawValue: entry.section) {
            case .personalTime:
                AddPersonalTimeView(entryToEdit: entry, section: .personalTime)
                    .environmentObject(tagStore)
            case .sermonNotes:
                AddSermonNotesView(entryToEdit: entry, section: .sermonNotes)
                    .environmentObject(tagStore)
                    .environmentObject(speakerStore)
            case .scriptureMemorization, .prayerJournal, .prayerRequest, .groupNotes, .other, .none:
                AddEntryView(entryToEdit: entry, section: JournalSection(rawValue: entry.section) ?? .other)
                    .environmentObject(tagStore)
            }
        }
        .sheet(item: Binding<Binder?>(
            get: { showBinderFunctionality && showBinderContents ? selectedBinder : nil },
            set: { _ in showBinderContents = false; selectedBinder = nil }
        )) { binder in
            NavigationStack {
                BinderContentsView(binder: binder)
                    .environmentObject(binderStore)
                    .environmentObject(tagStore)
                    .environmentObject(speakerStore)
                    .environmentObject(memorizationSettings)
                    .environmentObject(prayerCategoryStore)
                    .environmentObject(prayerRequestStore)
                    .navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarHidden(true)
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Binding(
            get: { showBinderFunctionality && showBinderSelector },
            set: { showBinderSelector = $0 }
        )) {
            NavigationView {
                binderSelectorView
            }
        }
    }
    
    // MARK: - Binder Actions
    
    private func handleBinderIconTap() {
        if entryBinders.count == 1 {
            // Direct navigation to single binder
            selectedBinder = entryBinders.first
            showBinderContents = true
        } else if entryBinders.count > 1 {
            // Show selector for multiple binders
            showBinderSelector = true
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var scripturePassageSection: some View {
        if let scripture = entry.scripture, !scripture.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(scripturePassages.count == 1 ? "Scripture Passage" : "Scripture Passages")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appGreenDark)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], alignment: .leading, spacing: 8) {
                    ForEach(scripturePassages, id: \.self) { passage in
                        Text(passage.trimmingCharacters(in: .whitespacesAndNewlines))
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.appGreen.opacity(0.2))
                            )
                            .foregroundColor(.appGreenDark)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var speakerAndTagsSection: some View {
        let userTags = entry.tagIDs.compactMap { tagID in
            tagStore.userTags.first { $0.id == tagID }
        }
        let hasSpeaker = (entry.section == JournalSection.sermonNotes.rawValue || entry.section == JournalSection.groupNotes.rawValue) && !(entry.speaker?.isEmpty ?? true)
        let hasTags = !userTags.isEmpty
        
        if hasSpeaker && hasTags {
            HStack(spacing: 12) {
                speakerSection
                Spacer()
                tagsSection
            }
        }
        
        if !hasSpeaker && hasTags {
            tagsSection
        }
    }
    
    @ViewBuilder
    private var speakerSection: some View {
        let hasSpeaker = (entry.section == JournalSection.sermonNotes.rawValue || entry.section == JournalSection.groupNotes.rawValue) && !(entry.speaker?.isEmpty ?? true)
        
        if hasSpeaker, let speaker = entry.speaker {
            VStack(alignment: .leading, spacing: 8) {
                Text("Speaker")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appGreenDark)
                
                Text(speaker)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appGreenLight.opacity(0.3))
                    )
                    .foregroundColor(.appGreenDark)
            }
        }
    }
    
    @ViewBuilder
    private var tagsSection: some View {
        let userTags = entry.tagIDs.compactMap { tagID in
            tagStore.userTags.first { $0.id == tagID }
        }
        
        if !userTags.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.appGreenDark)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], alignment: .leading, spacing: 8) {
                    ForEach(userTags, id: \.id) { tag in
                        Text(tag.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.appGreenMedium.opacity(0.3))
                            )
                            .foregroundColor(.appGreenDark)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var binderSelectorView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "books.vertical.fill")
                        .font(.title2)
                        .foregroundColor(.appGreenDark)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Select Binder")
                            .font(.headline)
                            .foregroundColor(.appGreenDark)
                        
                        Text("This entry is in \(entryBinders.count) binders")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Cancel") {
                        showBinderSelector = false
                    }
                    .foregroundColor(.appGreenDark)
                }
                
                Divider()
            }
            .padding()
            .background(Color.appGreenPale.opacity(0.1))
            
            // Binder list
            List {
                ForEach(entryBinders, id: \.id) { binder in
                    Button(action: {
                        selectedBinder = binder
                        showBinderSelector = false
                        showBinderContents = true
                    }) {
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(binder.color)
                                .frame(width: 4, height: 32)
                                .cornerRadius(2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(binder.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                if let description = binder.binderDescription, !description.isEmpty {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
    
    // Helper function for date formatting
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
}

struct JournalEntryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        JournalEntryDetailView(entry: previewJournalEntry)
            .environmentObject(previewTagStore)
            .environmentObject(previewSpeakerStore)
            .modelContainer(previewContainer)
    }
}
