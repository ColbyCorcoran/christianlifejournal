//
//  SpeakerPickerOverlay.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/19/25.
//

import SwiftUI

struct SpeakerPickerOverlay: View {
    @EnvironmentObject var speakerStore: SpeakerStore // Changed to @EnvironmentObject
    @Binding var isPresented: Bool
    @Binding var selectedSpeaker: String
    @State private var newSpeaker: String = ""
    @State private var tempSelection: String = ""
    
    private func dismissOverlay() {
        isPresented = false
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 18) {
                ZStack {
                    Text("Select Speaker")
                        .font(.headline)
                    HStack {
                        Button(action: dismissOverlay) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if !tempSelection.isEmpty {
                                selectedSpeaker = tempSelection
                            }
                            isPresented = false
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.appGreenDark)
                        }
                    }
                }
                .padding(.top, 8)

                List {
                    ForEach(speakerStore.speakers, id: \.id) { speaker in
                        HStack {
                            Text(speaker.name)
                            Spacer()
                            if tempSelection == speaker.name {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.appGreenDark)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            tempSelection = speaker.name
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.appWhite)
                .cornerRadius(10)
                .frame(maxHeight: 200)

                HStack {
                    TextField("New Speaker", text: $newSpeaker)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Create") {
                        let trimmed = newSpeaker.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty && !speakerStore.speakers.contains(where: { $0.name == trimmed }) {
                            speakerStore.addSpeaker(trimmed)
                            tempSelection = trimmed
                            newSpeaker = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.appGreenDark)
                }
                .padding(.top, 8)
            }
            .padding()
            .frame(width: 340, height: 320)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.appWhite)
                    .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
            )
            .onAppear {
                tempSelection = selectedSpeaker
            }
        }
    }
}

struct SpeakerPickerOverlay_Previews: PreviewProvider {
    static var previews: some View {
        SpeakerPickerOverlay(
            isPresented: .constant(true),
            selectedSpeaker: .constant("")
        )
        .environmentObject(SpeakerStore.preview)
    }
}
