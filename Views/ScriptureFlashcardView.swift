//
//  ScriptureFlashcardView.swift
//  Christian Life Journal
//
//  Created by Scripture Memorization System Implementation
//

import SwiftUI
import SwiftData

struct ScriptureFlashcardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var memorizationSettings: MemorizationSettings
    
    let entry: ScriptureMemoryEntry
    
    @State private var showingReference = true
    @State private var isFlipping = false
    @State private var showingEditView = false
    @State private var rotationAngle: Double = 0
    
    // Computed properties for completion status
    private var canCompleteToday: Bool {
        guard memorizationSettings.isSystemEnabled else { return true }
        return entry.needsCompletionOn(date: Date())
    }
    
    private var hasCompletedToday: Bool {
        guard memorizationSettings.isSystemEnabled else { return false }
        return !entry.needsCompletionOn(date: Date())
    }
    
    private var completionButtonText: String {
        if !memorizationSettings.isSystemEnabled {
            return "Review Complete"
        }
        
        if hasCompletedToday {
            return "✓ Completed Today"
        } else {
            return entry.currentDayCompletionText()
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appWhite.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Flashcard
                    flashcardView
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
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
            .navigationTitle("Scripture Card")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.appGreenDark)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditView = true
                    }
                    .foregroundColor(.appGreenDark)
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            AddScriptureMemoryView(entryToEdit: entry)
                .environmentObject(memorizationSettings)
        }
    }
    
    // MARK: - Flashcard View
    
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
            
            // Card content
            VStack {
                if showingReference {
                    referenceCardContent
                } else {
                    passageCardContent
                }
            }
            .padding(24)
            .opacity(isFlipping ? 0 : 1)
        }
        .frame(minHeight: 300)
        .rotation3DEffect(
            .degrees(rotationAngle),
            axis: (x: 0, y: 1, z: 0)
        )
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
            
            // Passage text
            ScrollView {
                Text(entry.passageText)
                    .font(.body)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            // Reference reminder
            Text(entry.bibleReference)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.appGreenDark)
        }
    }
    
    // MARK: - Phase Indicators
    
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
                        .foregroundColor(.green)
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
                        .foregroundColor(isCompleted ? .green : .gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isCompleted ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
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
                        .foregroundColor(.green)
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
                        .fill(Color.green)
                        .frame(width: 2, height: 12)
                }
            }
            
            // Diagonal mark for 5th tally
            if markCount == 5 {
                Rectangle()
                    .fill(Color.green)
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
                    .fill(hasCompletedToday ? Color.green : Color.appGreenDark)
            )
        }
        .disabled(hasCompletedToday && memorizationSettings.isSystemEnabled)
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    private func flipCard() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isFlipping = true
            rotationAngle += 90
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            showingReference.toggle()
            
            withAnimation(.easeInOut(duration: 0.3)) {
                rotationAngle += 90
                isFlipping = false
            }
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
        guard memorizationSettings.isSystemEnabled else { return }
        
        do {
            try MemorizationEngine.processCompletion(for: entry, modelContext: modelContext)
        } catch {
            print("Error saving completion: \(error)")
        }
    }
}

// MARK: - Preview

struct ScriptureFlashcardView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: ScriptureMemoryEntry.self, configurations: config)
        
        let sampleEntry = ScriptureMemoryEntry(
            bibleReference: "John 3:16",
            passageText: "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.",
            isSystemManaged: true
        )
        
        // Set some sample progress
        sampleEntry.phase1Progress.daysCompleted = 3
        sampleEntry.phase2Progress.daysCompleted = 45
        sampleEntry.phase3Progress.monthsCompleted = 5
        
        return ScriptureFlashcardView(entry: sampleEntry)
            .environmentObject(MemorizationSettings())
            .environmentObject(TagStore())
            .modelContainer(container)
    }
}
