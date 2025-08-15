//
//  PrayerRequestDetailView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/11/25.
//

import SwiftUI
import SwiftData

struct PrayerRequestDetailView: View {
    @EnvironmentObject var prayerRequestStore: PrayerRequestStore
    @EnvironmentObject var prayerCategoryStore: PrayerCategoryStore
    @EnvironmentObject var tagStore: TagStore
    
    let prayerRequest: PrayerRequest
    
    @State private var showEditSheet = false
    @State private var showAnswerModal = false
    @State private var showCelebrationModal = false
    @State private var answerDate = Date()
    @State private var answerNotes = ""
    
    var body: some View {
        ZStack {
            Color.appWhite.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Request Details Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Prayer Request")
                                .font(.headline)
                                .foregroundColor(.appGreenDark)
                            
                            Spacer()
                            
                            Text(prayerRequest.formattedDateAdded)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Request")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.appGreenDark)
                            
                            Text(prayerRequest.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    
                    // Description Card
                    if !prayerRequest.requestDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Details")
                                .font(.headline)
                                .foregroundColor(.appGreenDark)
                            
                            Text(prayerRequest.requestDescription)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.appGreenPale.opacity(0.2))
                                )
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                    }
                    
                    // Categories, Scripture, and Tags Card
                    let categoryNames = prayerRequest.categoryIDs.compactMap { categoryID in
                        prayerCategoryStore.categoryName(for: categoryID)
                    }
                    let userTags = prayerRequest.tagIDs.compactMap { tagID in
                        tagStore.userTags.first { $0.id == tagID }
                    }
                    let hasCategories = !categoryNames.isEmpty
                    let hasTags = !userTags.isEmpty
                    let hasScripture = prayerRequest.scripture?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                    
                    if hasCategories || hasTags || hasScripture {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Organization")
                                .font(.headline)
                                .foregroundColor(.appGreenDark)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 12) {
                                    // Categories section
                                    if hasCategories {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(categoryNames.count == 1 ? "Category" : "Categories")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.appGreenDark)
                                            
                                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], alignment: .leading, spacing: 8) {
                                                ForEach(categoryNames, id: \.self) { categoryName in
                                                    Text(categoryName)
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
                                        }
                                    }
                                    
                                    // Scripture section
                                    if hasScripture, let scripture = prayerRequest.scripture {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Scripture Passage")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.appGreenDark)
                                            
                                            Text(scripture)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                                .padding(12)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color.appGreen.opacity(0.1))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 8)
                                                                .stroke(Color.appGreen.opacity(0.3), lineWidth: 1)
                                                        )
                                                )
                                        }
                                    }
                                    
                                    // Tags section
                                    if hasTags {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Tags")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.appGreenDark)
                                            
                                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], alignment: .leading, spacing: 8) {
                                                ForEach(userTags, id: \.id) { tag in
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
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                    }
                    
                    // Answer Status Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Prayer Status")
                            .font(.headline)
                            .foregroundColor(.appGreenDark)
                        
                        if prayerRequest.isAnswered {
                            // Answered status
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.appGreenDark)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Answered Prayer")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.appGreenDark)
                                        
                                        if let answerDate = prayerRequest.formattedDateAnswered {
                                            Text("Answered on \(answerDate)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        if let daysCount = prayerRequest.daysPrayedFor {
                                            Text("Prayed for \(daysCount) \(daysCount == 1 ? "day" : "days")")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                
                                // Answer notes if available
                                if let notes = prayerRequest.answerNotes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("How God Answered")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.appGreenDark)
                                        
                                        Text(notes)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .padding(12)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.appGreenLight.opacity(0.1))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(Color.appGreenDark.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                    }
                                }
                                
                                // Action button to mark as unanswered
                                Button(action: {
                                    prayerRequestStore.markAsUnanswered(prayerRequest)
                                }) {
                                    Text("Mark as Unanswered")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.appGreenMedium)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.appGreenMedium.opacity(0.5), lineWidth: 1)
                                                .background(Color.appGreenMedium.opacity(0.1))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            // Active status
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.appGreenMedium)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Active Request")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.appGreenMedium)
                                        
                                        let daysPraying = prayerRequest.daysSincePrayed
                                        Text("Praying for \(daysPraying) \(daysPraying == 1 ? "day" : "days")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                
                                // Action button to mark as answered
                                Button(action: {
                                    answerDate = Date()
                                    answerNotes = ""
                                    showAnswerModal = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                        
                                        Text("Mark as Answered")
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.appGreenDark)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showEditSheet = true
                }
                .foregroundColor(.appGreenDark)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddPrayerRequestView(requestToEdit: prayerRequest)
                .environmentObject(prayerRequestStore)
                .environmentObject(prayerCategoryStore)
                .environmentObject(tagStore)
        }
        .sheet(isPresented: $showAnswerModal) {
            AnswerPrayerModal(
                prayerRequest: prayerRequest,
                answerDate: $answerDate,
                answerNotes: $answerNotes,
                onSave: {
                    prayerRequestStore.markAsAnswered(prayerRequest, answerDate: answerDate, answerNotes: answerNotes)
                    showAnswerModal = false
                    showCelebrationModal = true
                },
                onCancel: {
                    showAnswerModal = false
                }
            )
        }
        .overlay {
            if showCelebrationModal {
                PrayerAnsweredCelebrationView(
                    prayerRequest: prayerRequest,
                    isPresented: $showCelebrationModal
                )
            }
        }
    }
}

// MARK: - Preview

struct PrayerRequestDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrayerRequestDetailView(prayerRequest: PrayerRequest(
                title: "Healing for Mom",
                requestDescription: "Please pray for my mother's recovery from surgery. She's been struggling with complications and could use prayers for healing and peace.",
                dateAdded: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                isAnswered: false
            ))
                .environmentObject(previewPrayerRequestStore)
                .environmentObject(previewPrayerCategoryStore)
                .environmentObject(previewTagStore)
        }
    }
}
