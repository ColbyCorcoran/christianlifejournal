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
    
    @EnvironmentObject var speakerStore: SpeakerStore
    @EnvironmentObject var tagStore: TagStore
    
    @State private var showEditSheet = false
    
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
                        
                        // Title content (or date display for Personal Time)
                        if entry.section == JournalSection.personalTime.rawValue {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Personal Time Entry")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.appGreenDark)
                                
                                Text(formattedDate(entry.date))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.appGreenDark)
                                
                                Text(entry.title)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
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
                Button("Edit") {
                    showEditSheet = true
                }
                .foregroundColor(.appGreenDark)
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
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var scripturePassageSection: some View {
        if let scripture = entry.scripture, !scripture.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Scripture Passages")
                    .font(.subheadline)
                    .foregroundColor(.appGreenDark)
                
                Text(scripture)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.appGreenPale.opacity(0.2))
                    )
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
        
        if hasSpeaker || hasTags {
            VStack(alignment: .leading, spacing: 12) {
                speakerSection
                tagsSection
            }
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
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.appGreenPale.opacity(0.2))
                    )
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
