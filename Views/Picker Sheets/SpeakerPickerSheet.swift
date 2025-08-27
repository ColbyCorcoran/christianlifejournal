//
//  SpeakerPickerSheet.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/14/25.
//

import SwiftUI

struct SpeakerPickerSheet: View {
    @Binding var selectedSpeaker: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var speakerStore: SpeakerStore
    
    @State private var searchText = ""
    @State private var newSpeakerName = ""
    @State private var showingAddSpeaker = false
    @State private var temporarySelectedSpeaker: String = ""
    
    private var filteredSpeakers: [Speaker] {
        if searchText.isEmpty {
            return speakerStore.speakers.sorted { $0.name < $1.name }
        } else {
            return speakerStore.speakers
                .filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.name < $1.name }
        }
    }
    
    private func selectSpeaker(_ speaker: Speaker) {
        temporarySelectedSpeaker = speaker.name
    }
    
    private func applySelection() {
        selectedSpeaker = temporarySelectedSpeaker
        dismiss()
    }
    
    private func cancelSelection() {
        dismiss()
    }
    
    private func addNewSpeaker() {
        guard !newSpeakerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let trimmedName = newSpeakerName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if speaker already exists
        if !speakerStore.speakers.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            speakerStore.addSpeaker(trimmedName)
            temporarySelectedSpeaker = trimmedName
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Find Speaker")
                        .font(.headline)
                        .foregroundColor(.appGreenDark)
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search speakers...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.appGreenDark.opacity(0.3), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.appGreenPale.opacity(0.1))
                            )
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Speakers list
                if !filteredSpeakers.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select Speaker")
                            .font(.headline)
                            .foregroundColor(.appGreenDark)
                            .padding(.horizontal, 20)
                        
                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(filteredSpeakers, id: \.id) { speaker in
                                    Button(action: { selectSpeaker(speaker) }) {
                                        HStack {
                                            Image(systemName: temporarySelectedSpeaker == speaker.name ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(temporarySelectedSpeaker == speaker.name ? .appGreenDark : .gray)
                                                .font(.title3)
                                            
                                            Text(speaker.name)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(temporarySelectedSpeaker == speaker.name ? Color.appGreenPale.opacity(0.3) : Color.clear)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
                } else if !searchText.isEmpty {
                    // No search results
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("No speakers found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Try a different search term or add a new speaker")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer()
                
                // Add new speaker section
                VStack(alignment: .leading, spacing: 12) {
                    
                        Text("Add New Speaker")
                            .font(.headline)
                            .foregroundColor(.appGreenDark)
                        
                        HStack {
                            TextField("Speaker name", text: $newSpeakerName)
                                .textFieldStyle(.plain)
                                .onSubmit {
                                    addNewSpeaker()
                                }
                            
                            Button("Add") {
                                addNewSpeaker()
                            }
                            .disabled(newSpeakerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .foregroundColor(.appGreenDark)
                            .fontWeight(.medium)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.appGreenDark, lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.appGreenPale.opacity(0.1))
                                )
                        )
                   
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.appWhite.ignoresSafeArea())
            .navigationTitle("Select Speaker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        cancelSelection()
                    }
                    .foregroundColor(.appGreenDark)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applySelection()
                    }
                    .foregroundColor(.appGreenDark)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Initialize temporary selection with current selection
                temporarySelectedSpeaker = selectedSpeaker
                
                // Focus search if no speakers exist
                if speakerStore.speakers.isEmpty {
                    showingAddSpeaker = true
                }
            }
        }
    }
}

// MARK: - Preview

struct SpeakerPickerSheet_Previews: PreviewProvider {
    static var previews: some View {
        SpeakerPickerSheet(selectedSpeaker: .constant(""))
            .environmentObject(SpeakerPickerPreviewStore())
    }
}

// MARK: - Mock Preview Store
class SpeakerPickerPreviewStore: ObservableObject {
    @Published var speakers: [Speaker] = [
        Speaker(name: "Pastor John"),
        Speaker(name: "Dr. Sarah Wilson"),
        Speaker(name: "Elder Mike Thompson")
    ]
    
    func addSpeaker(_ name: String) {
        let newSpeaker = Speaker(name: name)
        speakers.append(newSpeaker)
    }
    
    func removeSpeaker(withId id: UUID) {
        speakers.removeAll { $0.id == id }
    }
    
    func updateSpeaker(withId id: UUID, newName: String) {
        if let index = speakers.firstIndex(where: { $0.id == id }) {
            speakers[index].name = newName
        }
    }
}
