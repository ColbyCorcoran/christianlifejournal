//
//  BinderManagementSettingsView.swift
//  Christian Life Journal
//
//  Created by Claude on 8/27/25.
//

import SwiftUI

struct BinderManagementSettingsView: View {
    @EnvironmentObject var binderStore: BinderStore
    @State private var newBinderName: String = ""
    @State private var newBinderDescription: String = ""
    @State private var newBinderColorHex: String = "#4A7C59"
    @State private var editingBinderId: UUID? = nil
    @State private var editedBinderName: String = ""
    @State private var editedBinderDescription: String = ""
    @State private var binderToDelete: UUID? = nil

    var body: some View {
        List {
            // Info Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About Binders")
                        .font(.headline)
                        .foregroundColor(.appGreenDark)
                    
                    Text("Binders help you organize journal entries, prayer requests, and scripture verses into themed collections.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
            
            // Add New Binder Section
            Section("Add New Binder") {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Binder name...", text: $newBinderName)
                    
                    TextField("Description (optional)", text: $newBinderDescription)
                        .font(.caption)
                    
                    // Color Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.appGreenDark)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                            ForEach(Binder.defaultColors, id: \.self) { colorHex in
                                Button(action: {
                                    newBinderColorHex = colorHex
                                }) {
                                    Circle()
                                        .fill(Color(hex: colorHex))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    newBinderColorHex == colorHex ? Color.appGreenDark : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                        .overlay(
                                            newBinderColorHex == colorHex ? 
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white) : nil
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    
                    HStack {
                        Spacer()
                        Button("Add Binder") {
                            let trimmedName = newBinderName.trimmingCharacters(in: .whitespaces)
                            let trimmedDescription = newBinderDescription.trimmingCharacters(in: .whitespaces)
                            
                            let nameExists = binderStore.binders.contains { binder in
                                binder.name.caseInsensitiveCompare(trimmedName) == .orderedSame
                            }
                            
                            if !trimmedName.isEmpty && !nameExists {
                                let newBinder = Binder(
                                    name: trimmedName,
                                    binderDescription: trimmedDescription.isEmpty ? nil : trimmedDescription,
                                    colorHex: newBinderColorHex
                                )
                                binderStore.addBinder(newBinder)
                                newBinderName = ""
                                newBinderDescription = ""
                                newBinderColorHex = "#4A7C59"
                            }
                        }
                        .disabled(newBinderName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .foregroundColor(.appGreenDark)
                    }
                }
            }
            
            // Your Binders Section
            Section("Your Binders") {
                if binderStore.binders.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                        Text("No binders yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Create your first binder above")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(binderStore.binders, id: \.id) { binder in
                        binderRow(for: binder)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    binderToDelete = binder.id
                                }
                                
                                Button("Edit") {
                                    editedBinderName = binder.name
                                    editedBinderDescription = binder.binderDescription ?? ""
                                    editingBinderId = binder.id
                                }
                                .tint(.appGreenDark)
                            }
                    }
                }
            }
        }
        .navigationTitle("Manage Binders")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Binder?", isPresented: Binding(
            get: { binderToDelete != nil },
            set: { if !$0 { binderToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let binderId = binderToDelete {
                    binderStore.deleteBinder(withId: binderId)
                }
                binderToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                binderToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this binder? All entries will be removed from it, but the entries themselves will not be deleted.")
        }
        .onAppear {
            binderStore.refresh()
        }
    }
    
    @ViewBuilder
    private func binderRow(for binder: Binder) -> some View {
        if editingBinderId == binder.id {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Binder name", text: $editedBinderName)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Description", text: $editedBinderDescription)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                
                HStack {
                    Button("Cancel") {
                        editingBinderId = nil
                        editedBinderName = ""
                        editedBinderDescription = ""
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Save") {
                        let trimmedName = editedBinderName.trimmingCharacters(in: .whitespaces)
                        let trimmedDescription = editedBinderDescription.trimmingCharacters(in: .whitespaces)
                        
                        if !trimmedName.isEmpty {
                            binder.name = trimmedName
                            binder.binderDescription = trimmedDescription.isEmpty ? nil : trimmedDescription
                            binderStore.updateBinder(binder)
                        }
                        editingBinderId = nil
                        editedBinderName = ""
                        editedBinderDescription = ""
                    }
                    .disabled(editedBinderName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundColor(.appGreenDark)
                }
                .font(.caption)
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Vertical color strip
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: binder.colorHex))
                        .frame(width: 4)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(binder.name)
                            .font(.body)
                            .fontWeight(.medium)
                        
                        if let description = binder.binderDescription, !description.isEmpty {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Entry count indicator
                    let totalCount = binder.journalEntryIDs.count + binder.scriptureEntryIDs.count + binder.prayerRequestIDs.count
                    if totalCount > 0 {
                        Text("\(totalCount)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.appGreenPale.opacity(0.3))
                            .foregroundColor(.appGreenDark)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct BinderManagementSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BinderManagementSettingsView()
                .environmentObject(BinderStore(modelContext: previewContainer.mainContext))
        }
    }
}