//
//  SpeakerManagementView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/19/25.
//

import SwiftUI

struct SpeakerManagementView: View {
    @Binding var settingsPage: SettingsPage
    @ObservedObject var speakerStore: SpeakerStore
    @State private var newSpeaker: String = ""
    @State private var editingIndex: Int? = nil
    @State private var editedSpeaker: String = ""
    @State private var speakerToDelete: Int? = nil

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button(action: { settingsPage = .sectionControls }) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.top, 8)
            Text("\(Image(systemName: "person.2")) Speaker Management")
                .font(.headline)
                .padding(.bottom, 8)

            List {
                ForEach(speakerStore.speakers.indices, id: \.self) { idx in
                    HStack {
                        if editingIndex == idx {
                            TextField("Speaker Name", text: $editedSpeaker)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("Save") {
                                if !editedSpeaker.trimmingCharacters(in: .whitespaces).isEmpty {
                                    speakerStore.updateSpeaker(at: idx, with: editedSpeaker)
                                }
                                editingIndex = nil
                            }
                            .buttonStyle(.bordered)
                            .tint(.appGreenDark)
                        } else {
                            Text(speakerStore.speakers[idx])
                            Spacer()
                            Button(action: {
                                editedSpeaker = speakerStore.speakers[idx]
                                editingIndex = idx
                            }) {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.plain)
                            Button(action: {
                                speakerToDelete = idx
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .cornerRadius(10)
            .background(Color.appWhite)

            HStack {
                TextField("New Speaker", text: $newSpeaker)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Create") {
                    let trimmed = newSpeaker.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty && !speakerStore.speakers.contains(trimmed) {
                        speakerStore.addSpeaker(trimmed)
                        newSpeaker = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.appGreenDark)
            }
            .padding(.top, 8)
            Spacer()
        }
        .padding()
        .frame(width: 340, height: 420)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.appWhite)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
        .alert("Delete Speaker?", isPresented: Binding(
            get: { speakerToDelete != nil },
            set: { if !$0 { speakerToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let idx = speakerToDelete {
                    speakerStore.removeSpeaker(at: idx)
                }
                speakerToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                speakerToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this speaker?")
        }
    }
}

struct SpeakerManagementView_Previews: PreviewProvider {
    static var previews: some View {
        SpeakerManagementView(settingsPage: .constant(.sectionControls), speakerStore: SpeakerStore())
    }
}
