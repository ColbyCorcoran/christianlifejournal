//
//  ScriptureFlashcardView.swift
//  Christian Life Journal
//
//  Fixed version - corrected text rotation and completion logic
//

import SwiftUI
import SwiftData

struct ScriptureFlashcardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var memorizationSettings: MemorizationSettings
    @EnvironmentObject var binderStore: BinderStore
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var speakerStore: SpeakerStore
    @EnvironmentObject var prayerCategoryStore: PrayerCategoryStore
    @EnvironmentObject var prayerRequestStore: PrayerRequestStore
    
    let entry: ScriptureMemoryEntry
    let embedInNavigationView: Bool
    let showBinderFunctionality: Bool
    
    init(entry: ScriptureMemoryEntry, embedInNavigationView: Bool, showBinderFunctionality: Bool = true) {
        self.entry = entry
        self.embedInNavigationView = embedInNavigationView
        self.showBinderFunctionality = showBinderFunctionality
    }
    
    @State private var showingReference = true
    @State private var isFlipping = false
    @State private var showingEditView = false
    @State private var showBinderContents = false
    @State private var showBinderSelector = false
    @State private var selectedBinder: Binder?
    @State private var flipAngle: Double = 0
    
    // Computed properties for completion status
    private var canCompleteToday: Bool {
        guard memorizationSettings.isSystemEnabled else { return true }
        return entry.needsCompletionOn(date: Date())
    }
    
    private var hasCompletedToday: Bool {
        guard let lastCompletion = entry.lastCompletionDate else { return false }
        return Calendar.current.isDate(lastCompletion, inSameDayAs: Date())
    }
    
    private var completionButtonText: String {
        if !memorizationSettings.isSystemEnabled {
            return "Review Complete"
        }
        
        if hasCompletedToday {
            return "Completed Today"
        } else {
            return entry.currentDayCompletionText()
        }
    }
    
    // Computed properties for binder context
    private var entryBinders: [Binder] {
        binderStore.bindersContaining(scriptureEntryID: entry.id)
    }
    
    private var isInBinders: Bool {
        !entryBinders.isEmpty
    }
    
    var body: some View {
        Group {
            if embedInNavigationView {
                NavigationView {
                    flashcardContent
                }
            } else {
                flashcardContent
            }
        }
        .sheet(isPresented: $showingEditView) {
            AddScriptureMemoryView(entryToEdit: entry)
                .environmentObject(memorizationSettings)
        }
        .sheet(item: Binding<Binder?>(
            get: { showBinderFunctionality && showBinderContents ? selectedBinder : nil },
            set: { _ in showBinderContents = false; selectedBinder = nil }
        )) { binder in
            NavigationStack {
                BinderContentsView(binder: binder)
                    .environmentObject(binderStore)
                    .environmentObject(tagStore)
                    .environmentObject(speakerStore)
                    .environmentObject(memorizationSettings)
                    .environmentObject(prayerCategoryStore)
                    .environmentObject(prayerRequestStore)
                    .navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarHidden(true)
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Binding(
            get: { showBinderFunctionality && showBinderSelector },
            set: { showBinderSelector = $0 }
        )) {
            NavigationView {
                binderSelectorView
            }
        }
    }
    
    private var flashcardContent: some View {
        ZStack {
            Color.appWhite.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Flashcard
                flashcardView
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                Spacer()
                
                // Phase indicators (if system enabled)
                if memorizationSettings.isSystemEnabled {
                    phaseIndicatorsView
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                
                // Completion button
                completionButtonView
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Contextual binder icon - only show if entry is in binders and binder functionality is enabled
                    if showBinderFunctionality && isInBinders {
                        Button(action: {
                            handleBinderIconTap()
                        }) {
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.appGreenDark)
                        .accessibilityLabel(entryBinders.count == 1 ? "View Binder" : "View Binders")
                    }
                    
                    Button("Edit") {
                        showingEditView = true
                    }
                    .foregroundColor(.appGreenDark)
                }
            }
        }
    }
    
    // MARK: - Flashcard View (FIXED)
    
    private var flashcardView: some View {
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appGreenDark.opacity(0.2), lineWidth: 1)
                    )
                
                // Card content - FIXED: Remove rotation effect that was causing text to be mirrored
                VStack {
                    if showingReference {
                        referenceCardContent
                            .opacity(isFlipping ? 0 : 1)
                    } else {
                        passageCardContent
                            .opacity(isFlipping ? 0 : 1)
                    }
                }
                .padding(24)
            }
            .frame(minHeight: 300)
            .scaleEffect(x: isFlipping ? -1 : 1) // Use scale effect instead of rotation3D for smooth flip without text reversal
            .onTapGesture {
                flipCard()
            }
        }
        
        private var referenceCardContent: some View {
            VStack(spacing: 16) {
                // Card type indicator
                HStack {
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(.appGreenDark)
                    Text("Reference")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.appGreenDark)
                    Spacer()
                    
                    // Flip indicator
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Bible reference
                Text(entry.bibleReference)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.appGreenDark)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // Instruction
                Text("Tap to reveal passage")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        
        private var passageCardContent: some View {
            VStack(spacing: 16) {
                // Card type indicator
                HStack {
                    Image(systemName: "text.quote")
                        .foregroundColor(.appGreenDark)
                    Text("Passage")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.appGreenDark)
                    Spacer()
                    
                    // Flip indicator
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Passage text with separated verses and superscript numbers
                ScrollView {
                    if !entry.individualVerses.isEmpty {
                        versesWithSuperscriptNumbers
                    } else {
                        // Fallback to passage text if individual verses is empty
                        Text(entry.passageText)
                            .font(fontSizeForContent(entry.passageText))
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer()
                
                // Reference reminder
                Text(entry.bibleReference)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.appGreenDark)
            }
        }
        
        // MARK: - Phase Indicators (No changes needed)
        
        private var phaseIndicatorsView: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Progress")
                    .font(.headline)
                    .foregroundColor(.appGreenDark)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Phase 1 indicators
                    if entry.phase1Progress.daysCompleted > 0 || entry.currentPhase == .phase1 {
                        phase1IndicatorView
                    }
                    
                    // Phase 2 indicators
                    if entry.phase2Progress.daysCompleted > 0 || entry.currentPhase == .phase2 {
                        phase2IndicatorView
                    }
                    
                    // Phase 3 indicators
                    if entry.phase3Progress.monthsCompleted > 0 || entry.currentPhase == .phase3 {
                        phase3IndicatorView
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appGreenPale.opacity(0.3))
            )
        }
        
        private var phase1IndicatorView: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Phase 1")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appGreenDark)
                    
                    if entry.phase1Progress.isPhaseComplete(for: .phase1) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.appGreenMedium)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { day in
                        let repetitions = phase1Repetitions(for: day)
                        let isCompleted = day <= entry.phase1Progress.daysCompleted
                        
                        Text(isCompleted ? "\(repetitions)" : "\(repetitions)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(isCompleted ? .appGreenDark : .gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isCompleted ? Color.appGreenMedium.opacity(0.3) : Color.gray.opacity(0.1))
                            )
                    }
                }
            }
        }
        
        private var phase2IndicatorView: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Phase 2")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appGreenDark)
                    
                    if entry.phase2Progress.isPhaseComplete(for: .phase2) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.appGreenMedium)
                    }
                    
                    Spacer()
                    
                    Text("\(entry.phase2Progress.daysCompleted)/45 days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Tally marks (groups of 5)
                let tallyGroups = (entry.phase2Progress.daysCompleted + 4) / 5
                let remainingInLastGroup = entry.phase2Progress.daysCompleted % 5
                
                HStack(spacing: 4) {
                    ForEach(0..<max(1, tallyGroups), id: \.self) { groupIndex in
                        let isLastGroup = groupIndex == tallyGroups - 1
                        let marksInGroup = isLastGroup && remainingInLastGroup > 0 ? remainingInLastGroup : min(5, entry.phase2Progress.daysCompleted - (groupIndex * 5))
                        
                        if marksInGroup > 0 {
                            tallyGroup(markCount: marksInGroup)
                        }
                    }
                }
            }
        }
        
        private var phase3IndicatorView: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Phase 3")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.appGreenDark)
                    
                    Spacer()
                    
                    Text("\(entry.phase3Progress.monthsCompleted) months")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Monthly tally marks
                let tallyGroups = (entry.phase3Progress.monthsCompleted + 4) / 5
                let remainingInLastGroup = entry.phase3Progress.monthsCompleted % 5
                
                HStack(spacing: 4) {
                    ForEach(0..<max(1, tallyGroups), id: \.self) { groupIndex in
                        let isLastGroup = groupIndex == tallyGroups - 1
                        let marksInGroup = isLastGroup && remainingInLastGroup > 0 ? remainingInLastGroup : min(5, entry.phase3Progress.monthsCompleted - (groupIndex * 5))
                        
                        if marksInGroup > 0 {
                            tallyGroup(markCount: marksInGroup)
                        }
                    }
                }
            }
        }
        
        // MARK: - Helper Views
        
        private func tallyGroup(markCount: Int) -> some View {
            ZStack {
                // Vertical tally marks
                HStack(spacing: 2) {
                    ForEach(0..<min(markCount, 4), id: \.self) { _ in
                        Rectangle()
                            .fill(Color.appGreenMedium)
                            .frame(width: 2, height: 12)
                    }
                }
                
                // Diagonal mark for 5th tally
                if markCount == 5 {
                    Rectangle()
                        .fill(Color.appGreenMedium)
                        .frame(width: 16, height: 2)
                        .rotationEffect(.degrees(-45))
                }
            }
            .frame(width: 20, height: 16)
        }
        
        // MARK: - Completion Button
        
        private var completionButtonView: some View {
            Button(action: {
                completeToday()
            }) {
                HStack {
                    if hasCompletedToday {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.white)
                    }
                    
                    Text(completionButtonText)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(hasCompletedToday ? Color.appGreenDark : Color.appGreenDark)
                )
            }
            .disabled(hasCompletedToday)
            .buttonStyle(PlainButtonStyle())
        }
        
        // MARK: - Verse Display Components
        
        @ViewBuilder
        private var versesWithSuperscriptNumbers: some View {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(entry.individualVerses.sorted(by: { $0.key < $1.key }), id: \.key) { verseNumber, verseText in
                    HStack(alignment: .top, spacing: 4) {
                        // Superscript-style verse number
                        Text("\(verseNumber)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.appGreenDark.opacity(0.7))
                            .offset(y: -2) // Slightly raised like a superscript
                        
                        // Verse text with auto-scaling
                        Text(verseText)
                            .font(fontSizeForContent(verseText))
                            .lineSpacing(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        // MARK: - Helper Methods
        
        /// Auto-scales font size based on content length
        private func fontSizeForContent(_ content: String) -> Font {
            let characterCount = content.count
            
            // Adjust font size based on content length
            switch characterCount {
            case 0...200:
                return .body
            case 201...400:
                return .callout
            case 401...600:
                return .caption
            default:
                return .caption2
            }
        }
        
        private func flipCard() {
            withAnimation(.easeInOut(duration: 0.3)) {
                isFlipping = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingReference.toggle()
                isFlipping = false
            }
        }
        
        private func phase1Repetitions(for day: Int) -> Int {
            switch day {
            case 1: return 25
            case 2: return 20
            case 3: return 15
            case 4: return 10
            case 5: return 5
            default: return 0
            }
        }
        
        private func completeToday() {
            if memorizationSettings.isSystemEnabled {
                // Full memorization system functionality
                do {
                    try MemorizationEngine.processCompletion(for: entry, modelContext: modelContext)
                } catch {
                    print("Error saving completion: \(error)")
                }
            } else {
                // Simple review tracking when system is disabled
                entry.lastCompletionDate = Date()
                
                do {
                    try modelContext.save()
                } catch {
                    print("Error saving review completion: \(error)")
                }
            }
        }
    
    // MARK: - Binder Actions
    
    private func handleBinderIconTap() {
        if entryBinders.count == 1 {
            // Direct navigation to single binder
            selectedBinder = entryBinders.first
            showBinderContents = true
        } else if entryBinders.count > 1 {
            // Show selector for multiple binders
            showBinderSelector = true
        }
    }
    
    @ViewBuilder
    private var binderSelectorView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "books.vertical.fill")
                        .font(.title2)
                        .foregroundColor(.appGreenDark)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Select Binder")
                            .font(.headline)
                            .foregroundColor(.appGreenDark)
                        
                        Text("This entry is in \(entryBinders.count) binders")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Cancel") {
                        showBinderSelector = false
                    }
                    .foregroundColor(.appGreenDark)
                }
                
                Divider()
            }
            .padding()
            .background(Color.appGreenPale.opacity(0.1))
            
            // Binder list
            List {
                ForEach(entryBinders, id: \.id) { binder in
                    Button(action: {
                        selectedBinder = binder
                        showBinderSelector = false
                        showBinderContents = true
                    }) {
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(binder.color)
                                .frame(width: 4, height: 32)
                                .cornerRadius(2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(binder.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                if let description = binder.binderDescription, !description.isEmpty {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

// MARK: - Preview

struct ScriptureFlashcardView_Previews: PreviewProvider {
    static var previews: some View {
        ScriptureFlashcardView(entry: previewScriptureMemoryEntry, embedInNavigationView: true)
            .environmentObject(previewMemorizationSettings)
            .modelContainer(previewContainer)
    }
}
