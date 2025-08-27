//
//  MockEntryView.swift
//  Christian Life Journal
//
//  Created by Claude on 8/27/25.
//

import SwiftUI
import SwiftData

struct MockEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var speakerStore: SpeakerStore
    @EnvironmentObject var prayerCategoryStore: PrayerCategoryStore
    @EnvironmentObject var binderStore: BinderStore
    
    // Entry properties
    @State private var title: String = ""
    @State private var bodyText: String = ""
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isBodyFocused: Bool
    
    // Selection states
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var selectedSpeaker: String = ""
    @State private var selectedCategoryIDs: Set<UUID> = []
    @State private var selectedPassages: [ScripturePassageSelection] = []
    @State private var selectedBinderIDs: Set<UUID> = []
    
    // Sheet presentation states
    @State private var showTagPicker = false
    @State private var showSpeakerPicker = false
    @State private var showCategoryPicker = false
    @State private var showScripturePicker = false
    @State private var showBinderPicker = false
    @State private var showLeaveAlert = false
    
    let date = Date()
    
    var body: some View {
        ZStack {
            Color.appWhite.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content area
                VStack(alignment: .leading, spacing: 16) {
                    // Title and Date header
                    HStack(alignment: .center) {
                        TextField("Title", text: $title)
                            .font(.title2)
                            .fontWeight(.medium)
                            .focused($isTitleFocused)
                            .textFieldStyle(.plain)
                        
                        Spacer()
                        
                        Text(formattedDate(date))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 0.5)
                    
                    // Body text editor
                    ZStack(alignment: .topLeading) {
                        if bodyText.isEmpty {
                            Text("Record your thoughts, reflections, and insights...")
                                .foregroundColor(.secondary)
                                .font(.body)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                        
                        TextEditor(text: $bodyText)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .focused($isBodyFocused)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Floating toolbar
                floatingToolbar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    if hasUnsavedChanges {
                        showLeaveAlert = true
                    } else {
                        dismiss()
                    }
                }
                .foregroundColor(.appGreenDark)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    saveEntry()
                }
                .disabled(!canSave)
                .fontWeight(.medium)
                .foregroundColor(canSave ? .appGreenDark : .secondary)
            }
        }
        .onAppear {
            // Focus title field when view appears
            isTitleFocused = true
        }
        .alert("Unsaved Changes", isPresented: $showLeaveAlert) {
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to leave without saving?")
        }
        .sheet(isPresented: $showTagPicker) {
            TagPickerSheet(selectedTagIDs: $selectedTagIDs)
                .environmentObject(tagStore)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSpeakerPicker) {
            SpeakerPickerSheet(selectedSpeaker: $selectedSpeaker)
                .environmentObject(speakerStore)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCategoryPicker) {
            PrayerCategoryPickerSheet(selectedCategoryIDs: $selectedCategoryIDs)
                .environmentObject(prayerCategoryStore)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showScripturePicker) {
            ScripturePickerSheet(selectedPassages: $selectedPassages)
                .presentationDetents([.large, .medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBinderPicker) {
            BinderPickerSheet(selectedBinderIDs: $selectedBinderIDs)
                .environmentObject(binderStore)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Floating Toolbar
    
    @ViewBuilder
    private var floatingToolbar: some View {
        HStack(spacing: 32) {
            // Tags button
            Button(action: { showTagPicker = true }) {
                ZStack {
                    Image(systemName: selectedTagIDs.isEmpty ? "tag" : "tag.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(selectedTagIDs.isEmpty ? .secondary : .appGreenDark)
                        .frame(width: 24, height: 24)
                    
                    if !selectedTagIDs.isEmpty {
                        Text("\(selectedTagIDs.count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.appGreenDark)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.appWhite)
                            .clipShape(Circle())
                            .offset(x: 12, y: -12)
                    }
                }
            }
            
            // Speaker button
            Button(action: { showSpeakerPicker = true }) {
                ZStack {
                    Image(systemName: selectedSpeaker.isEmpty ? "person" : "person.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(selectedSpeaker.isEmpty ? .secondary : .appGreenDark)
                        .frame(width: 24, height: 24)
                    
                    if !selectedSpeaker.isEmpty {
                        Text("1")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.appGreenDark)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.appWhite)
                            .clipShape(Circle())
                            .offset(x: 12, y: -12)
                    }
                }
            }
            
            // Categories button
            Button(action: { showCategoryPicker = true }) {
                ZStack {
                    Image(systemName: selectedCategoryIDs.isEmpty ? "folder" : "folder.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(selectedCategoryIDs.isEmpty ? .secondary : .appGreenDark)
                        .frame(width: 24, height: 24)
                    
                    if !selectedCategoryIDs.isEmpty {
                        Text("\(selectedCategoryIDs.count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.appGreenDark)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.appWhite)
                            .clipShape(Circle())
                            .offset(x: 12, y: -12)
                    }
                }
            }
            
            // Scripture button
            Button(action: { showScripturePicker = true }) {
                ZStack {
                    Image(systemName: selectedPassages.isEmpty ? "book" : "book.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(selectedPassages.isEmpty ? .secondary : .appGreenDark)
                        .frame(width: 24, height: 24)
                    
                    if !selectedPassages.isEmpty {
                        Text("\(selectedPassages.count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.appGreenDark)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.appWhite)
                            .clipShape(Circle())
                            .offset(x: 12, y: -12)
                    }
                }
            }
            
            // Binders button
            Button(action: { showBinderPicker = true }) {
                ZStack {
                    Image(systemName: selectedBinderIDs.isEmpty ? "books.vertical" : "books.vertical.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(selectedBinderIDs.isEmpty ? .secondary : .appGreenDark)
                        .frame(width: 24, height: 24)
                    
                    if !selectedBinderIDs.isEmpty {
                        Text("\(selectedBinderIDs.count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.appGreenDark)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.appWhite)
                            .clipShape(Circle())
                            .offset(x: 12, y: -12)
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.appGreenPale)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Computed Properties
    
    private var hasUnsavedChanges: Bool {
        return !title.isEmpty || 
               !bodyText.isEmpty || 
               !selectedTagIDs.isEmpty || 
               !selectedSpeaker.isEmpty || 
               !selectedCategoryIDs.isEmpty || 
               !selectedPassages.isEmpty || 
               !selectedBinderIDs.isEmpty
    }
    
    private var canSave: Bool {
        return !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // MARK: - Actions
    
    private func saveEntry() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        
        // Create scripture string
        let passagesString = selectedPassages.compactMap { passage in
            return passage.displayString(bibleBooks: bibleBooks)
        }
        .filter { !$0.isEmpty }
        .joined(separator: "; ")
        
        // Create new entry
        let newEntry = JournalEntry(
            section: JournalSection.other.rawValue, // Using "other" as default for mock
            title: trimmedTitle,
            date: date,
            scripture: passagesString,
            notes: bodyText.isEmpty ? nil : bodyText,
            speaker: selectedSpeaker.isEmpty ? nil : selectedSpeaker
        )
        
        // Set additional properties
        newEntry.tagIDs = Array(selectedTagIDs)
        // Note: JournalEntry doesn't have prayerCategoryID field - categories are handled by PrayerRequest model
        
        // Save to context
        modelContext.insert(newEntry)
        
        // Add to selected binders
        for binderID in selectedBinderIDs {
            binderStore.addEntry(newEntry, to: binderID)
        }
        
        dismiss()
    }
    
    // MARK: - Helper Functions
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct MockEntryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MockEntryView()
                .environmentObject(previewTagStore)
                .environmentObject(previewSpeakerStore)
                .environmentObject(PrayerCategoryStore(modelContext: previewContainer.mainContext))
                .environmentObject(BinderStore(modelContext: previewContainer.mainContext))
                .modelContainer(previewContainer)
        }
    }
}
