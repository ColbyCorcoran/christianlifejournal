//
//  SpeakerPickerOverlay.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/19/25.
//

import SwiftUI

struct SpeakerPickerOverlay: View {
    @ObservedObject var speakerStore: SpeakerStore
    @Binding var isPresented: Bool
    @Binding var selectedSpeaker: String
    @State private var newSpeaker: String = ""
    @State private var tempSelection: String = ""

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
                    ForEach(speakerStore.speakers, id: \.self) { speaker in
                        HStack {
                            Text(speaker)
                            Spacer()
                            if tempSelection == speaker {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.appGreenDark)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            tempSelection = speaker
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
                        if !trimmed.isEmpty && !speakerStore.speakers.contains(trimmed) {
                            speakerStore.addSpeaker(trimmed)
                            tempSelection = trimmed
                            newSpeaker = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.appGreenDark)
                }
                .padding(.top, 8)
//                Spacer()
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
            speakerStore: SpeakerStore(),
            isPresented: .constant(true),
            selectedSpeaker: .constant("")
        )
    }
}

