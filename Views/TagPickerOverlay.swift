//
//  TagPickerOverlay.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/30/25.
//

import SwiftUI

struct TagPickerOverlay: View {
    @ObservedObject var tagStore: TagStore
    @Binding var isPresented: Bool
    @Binding var selectedTags: Set<String> // Set of tag names
    @State private var tempSelection: Set<String> = []
    @State private var newTag: String = ""
    
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
                    Text("Select Tags")
                        .font(.headline)
                    
                    HStack {
                        Button(action: dismissOverlay) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            selectedTags = tempSelection
                            isPresented = false
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.appGreenDark)
                        }
                    }
                    .padding(.top, 8)
                }

                List {
                    ForEach(tagStore.userTags, id: \.id) { tag in
                        HStack {
                            Text(tag.name)
                            Spacer()
                            if tempSelection.contains(tag.name) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.appGreenDark)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if tempSelection.contains(tag.name) {
                                tempSelection.remove(tag.name)
                            } else {
                                tempSelection.insert(tag.name)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.appWhite)
                .cornerRadius(10)
                .frame(maxHeight: 200)

                HStack {
                    TextField("New Tag", text: $newTag)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Create") {
                        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty && !tagStore.userTags.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                            tagStore.addUserTag(trimmed)
                            tempSelection.insert(trimmed)
                            newTag = ""
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
                tempSelection = selectedTags
            }
        }
    }
}

struct TagPickerOverlay_Previews: PreviewProvider {
    static var previews: some View {
        TagPickerOverlay(
            tagStore: TagStore(),
            isPresented: .constant(true),
            selectedTags: .constant(["Prayer"])
        )
    }
}
