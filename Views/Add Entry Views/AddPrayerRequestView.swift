//
//  AddPrayerRequestView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/11/25.
//

import SwiftUI
import SwiftData

struct AddPrayerRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var prayerRequestStore: PrayerRequestStore
    @EnvironmentObject var prayerCategoryStore: PrayerCategoryStore
    @EnvironmentObject var tagStore: TagStore
    
    // Editing support
    let requestToEdit: PrayerRequest?
    
    // Form fields
    @State private var title: String = ""
    @State private var requestDescription: String = ""
    @State private var selectedCategoryIDs: Set<UUID> = []
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var selectedPassages: [ScripturePassageSelection] = []
    @State private var showTagPicker = false
    @State private var showCategoryPicker = false
    @State private var showScripturePicker = false
    
    init(requestToEdit: PrayerRequest? = nil) {
        self.requestToEdit = requestToEdit
    }
    
    var body: some View {
        NavigationView {
            mainContent
        }
    }
    
    // MARK: - Main Content View
    
    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            Color.appWhite.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    requestDetailsCard
                    categorySelectionCard
                    scriptureSelectionCard
                    tagsSelectionCard
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle(requestToEdit == nil ? "New Prayer Request" : "Edit Prayer Request")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.appGreenDark)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveRequest()
                }
                .foregroundColor(.appGreenDark)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            loadExistingData()
        }
        .sheet(isPresented: $showTagPicker) {
            TagPickerSheet(selectedTagIDs: $selectedTagIDs)
                .environmentObject(tagStore)
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
    }
    
    // MARK: - Request Details Card
    
    @ViewBuilder
    private var requestDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Request Details")
                    .font(.headline)
                    .foregroundColor(.appGreenDark)
                
                Spacer()
                
                if let request = requestToEdit {
                    Text(request.formattedDateAdded)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                titleField
                descriptionField
            }
        }
        .padding(16)
        .background(cardBackground)
    }
    
    @ViewBuilder
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.appGreenDark)
            
            TextField("Brief description of your prayer request", text: $title)
                .textFieldStyle(.plain)
                .padding(12)
                .background(textFieldBackground)
        }
    }
    
    @ViewBuilder
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.appGreenDark)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.appGreenDark.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.appGreenPale.opacity(0.1))
                    )
                    .frame(minHeight: 120)
                
                TextEditor(text: $requestDescription)
                    .padding(8)
                    .background(Color.clear)
                    .font(.body)
            }
        }
    }
    
    // MARK: - Category Selection Card
    
    @ViewBuilder
    private var categorySelectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
                .foregroundColor(.appGreenDark)
            
            Button(action: { showCategoryPicker = true }) {
                HStack {
                    Text("Add categories (optional)")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(12)
                .background(textFieldBackground)
            }
            .buttonStyle(.plain)
            
            // Display selected categories
            if !selectedCategoryIDs.isEmpty {
                selectedCategoriesGrid
            }
        }
        .padding(16)
        .background(cardBackground)
    }
    
    // MARK: - Tags Selection Card
    
    @ViewBuilder
    private var tagsSelectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(.appGreenDark)
            
            Button(action: { showTagPicker = true }) {
                HStack {
                    Text("Add tags (optional)")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(12)
                .background(textFieldBackground)
            }
            .buttonStyle(.plain)
            
            // Display selected tags
            if !selectedTagIDs.isEmpty {
                selectedTagsGrid
            }
        }
        .padding(16)
        .background(cardBackground)
    }
    
    @ViewBuilder
    private var selectedCategoriesGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], alignment: .leading, spacing: 8) {
            ForEach(selectedCategories, id: \.id) { category in
                Text(category.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appGreenLight.opacity(0.3))
                    )
                    .foregroundColor(.appGreenDark)
            }
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var selectedTagsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], alignment: .leading, spacing: 8) {
            ForEach(selectedTags, id: \.id) { tag in
                Text(tag.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appGreenMedium.opacity(0.3))
                    )
                    .foregroundColor(.appGreenDark)
            }
        }
        .padding(.top, 8)
    }
    
    
    // MARK: - Reusable Styling
    
    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var textFieldBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color.appGreenDark.opacity(0.3), lineWidth: 1)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.appGreenPale.opacity(0.1))
            )
    }
    
    // MARK: - Scripture Selection Card
    
    @ViewBuilder
    private var scriptureSelectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scripture Passages")
                .font(.headline)
                .foregroundColor(.appGreenDark)
            
            Button(action: { showScripturePicker = true }) {
                HStack {
                    if selectedPassages.isEmpty {
                        Text("Add Scripture references (optional)")
                            .font(.body)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(selectedPassages.count) selected")
                            .font(.body)
                            .foregroundColor(.appGreenDark)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(12)
                .background(textFieldBackground)
            }
            .buttonStyle(.plain)
            
            // Display selected passages
            if !selectedPassages.isEmpty {
                selectedPassagesGrid
            }
        }
        .padding(16)
        .background(cardBackground)
    }
    
    @ViewBuilder
    private var selectedPassagesGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], alignment: .leading, spacing: 8) {
            ForEach(selectedPassages.indices, id: \.self) { index in
                Text(selectedPassages[index].abbreviatedDisplayString(bibleBooks: bibleBooks) ?? "")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appGreenDark.opacity(0.1))
                    )
                    .foregroundColor(.appGreenDark)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Properties
    
    private var selectedCategories: [PrayerCategory] {
        selectedCategoryIDs.compactMap { categoryID in
            prayerCategoryStore.categories.first { $0.id == categoryID }
        }
    }
    
    private var selectedTags: [Tag] {
        selectedTagIDs.compactMap { tagID in
            tagStore.userTags.first { $0.id == tagID }
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func loadExistingData() {
        if let request = requestToEdit {
            title = request.title
            requestDescription = request.requestDescription
            selectedCategoryIDs = Set(request.categoryIDs)
            selectedTagIDs = Set(request.tagIDs)
            
            // Parse scripture passages if they exist
            if let scriptureString = request.scripture, !scriptureString.isEmpty {
                let components = scriptureString.components(separatedBy: ";")
                selectedPassages = components.compactMap { ref in
                    let trimmedRef = ref.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedRef.isEmpty else { return nil }
                    return parseScriptureReference(trimmedRef)
                }
            }
        }
    }
    
    private func parseScriptureReference(_ ref: String) -> ScripturePassageSelection? {
        let regex = #"^([1-3]?\s?[A-Za-z ]+)\s+(\d+):(\d+)(?:-(\d+))?$"#
        guard let match = ref.range(of: regex, options: .regularExpression) else { return nil }
        let comps = String(ref[match]).components(separatedBy: .whitespaces)
        let book = comps.dropLast().joined(separator: " ")
        let last = comps.last ?? ""
        let chapterVerse = last.components(separatedBy: ":")
        guard let chapter = Int(chapterVerse[0]) else { return nil }
        let verseRange = chapterVerse.count > 1 ? chapterVerse[1].split(separator: "-").compactMap { Int($0) } : []
        let verse = verseRange.first ?? 1
        let verseEnd = verseRange.count > 1 ? verseRange.last! : verse
        let bookIndex = bibleBooks.firstIndex(where: { $0.name == book }) ?? -1
        return ScripturePassageSelection(bookIndex: bookIndex, chapter: chapter, verse: verse, verseEnd: verseEnd)
    }
    
    private func saveRequest() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = requestDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else { return }
        
        // Format scripture passages
        let passagesString = selectedPassages.compactMap { passage in
            return passage.displayString(bibleBooks: bibleBooks)
        }
        .filter { !$0.isEmpty }
        .joined(separator: "; ")
        
        if let existingRequest = requestToEdit {
            // Update existing request
            existingRequest.title = trimmedTitle
            existingRequest.requestDescription = trimmedDescription
            existingRequest.categoryIDs = Array(selectedCategoryIDs)
            existingRequest.tagIDs = Array(selectedTagIDs)
            existingRequest.scripture = passagesString.isEmpty ? nil : passagesString
            
            prayerRequestStore.updatePrayerRequest(existingRequest)
        } else {
            // Create new request
            let newRequest = PrayerRequest(
                title: trimmedTitle,
                requestDescription: trimmedDescription,
                tagIDs: Array(selectedTagIDs),
                categoryIDs: Array(selectedCategoryIDs),
                scripture: passagesString.isEmpty ? nil : passagesString
            )
            
            prayerRequestStore.addPrayerRequest(newRequest)
        }
        
        dismiss()
    }
}

// MARK: - Preview

struct AddPrayerRequestView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // NUCLEAR OPTION: Completely separate preview that avoids ALL SwiftData
            SwiftDataFreePreviewAddPrayerRequestView()
        }
    }
}

// MARK: - SwiftData-Free Preview Implementation

struct SwiftDataFreePreviewAddPrayerRequestView: View {
    @State private var title: String = ""
    @State private var requestDescription: String = ""
    @State private var selectedCategoryIDs: Set<UUID> = []
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var showTagPicker = false
    @State private var showCategoryPicker = false
    
    var body: some View {
        ZStack {
            Color.appWhite.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    requestDetailsCard
                    categorySelectionCard
                    tagsSelectionCard
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("New Prayer Request")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    // No-op for preview
                }
                .foregroundColor(.appGreenDark)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    // No-op for preview
                }
                .foregroundColor(.appGreenDark)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    // MARK: - Request Details Card
    
    @ViewBuilder
    private var requestDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Request Details")
                    .font(.headline)
                    .foregroundColor(.appGreenDark)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                titleField
                descriptionField
            }
        }
        .padding(16)
        .background(cardBackground)
    }
    
    @ViewBuilder
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.appGreenDark)
            
            TextField("Brief description of your prayer request", text: $title)
                .textFieldStyle(.plain)
                .padding(12)
                .background(textFieldBackground)
        }
    }
    
    @ViewBuilder
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.appGreenDark)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.appGreenDark.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.appGreenPale.opacity(0.1))
                    )
                    .frame(minHeight: 120)
                
                TextEditor(text: $requestDescription)
                    .padding(8)
                    .background(Color.clear)
                    .font(.body)
            }
        }
    }
    
    // MARK: - Category Selection Card
    
    @ViewBuilder
    private var categorySelectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
                .foregroundColor(.appGreenDark)
            
            Button(action: { showCategoryPicker = true }) {
                HStack {
                    Text("Add categories (optional)")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(12)
                .background(textFieldBackground)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(cardBackground)
    }
    
    // MARK: - Tags Selection Card
    
    @ViewBuilder
    private var tagsSelectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(.appGreenDark)
            
            Button(action: { showTagPicker = true }) {
                HStack {
                    Text("Add tags (optional)")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(12)
                .background(textFieldBackground)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(cardBackground)
    }
    
    // MARK: - Reusable Styling
    
    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var textFieldBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color.appGreenDark.opacity(0.3), lineWidth: 1)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.appGreenPale.opacity(0.1))
            )
    }
}
