//
//  TagPickerOverlay.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/30/25.
//

import SwiftUI

struct TagPickerOverlay: View {
    @EnvironmentObject var tagStore: TagStore
    @Binding var isPresented: Bool
    @Binding var selectedTagIDs: Set<UUID>
    @State private var tempSelection: Set<UUID> = []
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
                            selectedTagIDs = tempSelection
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
                            if tempSelection.contains(tag.id) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.appGreenDark)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if tempSelection.contains(tag.id) {
                                tempSelection.remove(tag.id)
                            } else {
                                tempSelection.insert(tag.id)
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
                            // FIXED: Use the TagStore method instead of directly manipulating the array
                            tagStore.addUserTag(trimmed)
                            
                            // Find the newly created tag and add it to selection
                            if let newTagObj = tagStore.userTags.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                                tempSelection.insert(newTagObj.id)
                            }
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
                tempSelection = selectedTagIDs
            }
        }
    }
}

struct TagPickerOverlay_Previews: PreviewProvider {
    static var previews: some View {
        TagPickerOverlay(
            isPresented: .constant(true),
            selectedTagIDs: .constant([])
        )
        .environmentObject(TagStore()) // Add this line
    }
}
