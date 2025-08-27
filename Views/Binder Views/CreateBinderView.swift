//
//  CreateBinderView.swift
//  Christian Life Journal
//
//  View for creating new binders
//

import SwiftUI

struct CreateBinderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var binderStore: BinderStore
    
    @State private var name: String = ""
    @State private var binderDescription: String = ""
    @State private var selectedColorHex: String = "#4A7C59"
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appWhite.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Form Fields
                        formSection
                        
                        // Color Selection
                        colorSelectionSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("New Binder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.appGreenDark)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createBinder()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? .appGreenDark : .gray)
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Binder Details")
                .font(.headline)
                .foregroundColor(.appGreenDark)
            
            VStack(alignment: .leading, spacing: 12) {
                // Name field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.appGreenDark)
                    
                    TextField("Enter binder name", text: $name)
                        .font(.body)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                        )
                }
                
                // Description field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.appGreenDark)
                    
                    TextField("Enter description", text: $binderDescription, axis: .vertical)
                        .font(.body)
                        .lineLimit(3...6)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
        )
    }
    
    private var colorSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Color")
                .font(.headline)
                .foregroundColor(.appGreenDark)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                ForEach(Binder.defaultColors, id: \.self) { colorHex in
                    ColorSelectionButton(
                        colorHex: colorHex,
                        isSelected: selectedColorHex == colorHex
                    ) {
                        selectedColorHex = colorHex
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
        )
    }
    
    // MARK: - Actions
    
    private func createBinder() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = binderDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let newBinder = Binder(
            name: trimmedName,
            binderDescription: trimmedDescription.isEmpty ? nil : trimmedDescription,
            colorHex: selectedColorHex
        )
        
        binderStore.addBinder(newBinder)
        dismiss()
    }
}

// MARK: - Color Selection Button

struct ColorSelectionButton: View {
    let colorHex: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Consistent frame size for all buttons
                Circle()
                    .fill(Color.clear)
                    .frame(width: 52, height: 52)
                
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: 44, height: 44)
                
                if isSelected {
                    Circle()
                        .stroke(Color.appGreenDark, lineWidth: 3)
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

struct CreateBinderView_Previews: PreviewProvider {
    static var previews: some View {
        CreateBinderView()
            .environmentObject(previewBinderStore)
            .modelContainer(previewContainer)
    }
}