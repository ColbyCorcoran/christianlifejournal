//
//  SpeakerManagementSettingsView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/14/25.
//

import SwiftUI

struct SpeakerManagementSettingsView: View {
    @EnvironmentObject var speakerStore: SpeakerStore
    @State private var newSpeaker: String = ""
    @State private var editingSpeakerId: UUID? = nil
    @State private var editedSpeaker: String = ""
    @State private var speakerToDelete: UUID? = nil

    var body: some View {
        List {
            // Info Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About Speakers")
                        .font(.headline)
                        .foregroundColor(.appGreenDark)
                    
                    Text("Manage speakers for your sermon notes. Add pastors, teachers, or guest speakers to organize your notes.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
            
            // Add New Speaker Section
            Section("Add New Speaker") {
                HStack {
                    TextField("Speaker name...", text: $newSpeaker)
                    Button("Add") {
                        let trimmed = newSpeaker.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty && !speakerStore.speakers.contains(where: { $0.name == trimmed }) {
                            speakerStore.addSpeaker(trimmed)
                            newSpeaker = ""
                        }
                    }
                    .disabled(newSpeaker.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundColor(.appGreenDark)
                }
            }
            
            // Your Speakers Section
            Section("Your Speakers") {
                if speakerStore.speakers.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "person.2")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                        Text("No speakers added yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Add your first speaker above")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(speakerStore.speakers, id: \.id) { speaker in
                        speakerRow(for: speaker)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    speakerToDelete = speaker.id
                                }
                                
                                Button("Edit") {
                                    editedSpeaker = speaker.name
                                    editingSpeakerId = speaker.id
                                }
                                .tint(.appGreenDark)
                            }
                    }
                }
            }
        }
        .navigationTitle("Manage Speakers")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Speaker?", isPresented: Binding(
            get: { speakerToDelete != nil },
            set: { if !$0 { speakerToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let speakerId = speakerToDelete {
                    speakerStore.removeSpeaker(withId: speakerId)
                }
                speakerToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                speakerToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this speaker? This action cannot be undone.")
        }
        .onAppear {
            // Only refresh when not in preview mode
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                speakerStore.refresh()
            }
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func speakerRow(for speaker: Speaker) -> some View {
        if editingSpeakerId == speaker.id {
            HStack {
                TextField("Speaker name", text: $editedSpeaker)
                    .textFieldStyle(.roundedBorder)
                
                Button("Save") {
                    if !editedSpeaker.trimmingCharacters(in: .whitespaces).isEmpty {
                        speakerStore.updateSpeaker(withId: speaker.id, newName: editedSpeaker)
                    }
                    editingSpeakerId = nil
                    editedSpeaker = ""
                }
                .disabled(editedSpeaker.trimmingCharacters(in: .whitespaces).isEmpty)
                .foregroundColor(.appGreenDark)
                
                Button("Cancel") {
                    editingSpeakerId = nil
                    editedSpeaker = ""
                }
                .foregroundColor(.secondary)
            }
        } else {
            Label(speaker.name, systemImage: "person")
        }
    }
}

// MARK: - Preview

struct SpeakerManagementSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SpeakerManagementSettingsView()
                .environmentObject(previewSpeakerStore)
                .modelContainer(previewContainer)
        }
    }
}