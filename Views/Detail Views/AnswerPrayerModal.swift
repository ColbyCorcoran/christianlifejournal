//
//  AnswerPrayerModal.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/11/25.
//

import SwiftUI

struct AnswerPrayerModal: View {
    let prayerRequest: PrayerRequest
    @Binding var answerDate: Date
    @Binding var answerNotes: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appWhite.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.appGreenDark)
                        
                        Text("Mark as Answered")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.appGreenDark)
                        
                        Text("\(prayerRequest.title)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    VStack(spacing: 20) {
                        // Answer Date Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("When was this prayer answered?")
                                .font(.headline)
                                .foregroundColor(.appGreenDark)
                            
                            DatePicker(
                                "Answer Date",
                                selection: $answerDate,
                                in: prayerRequest.dateAdded...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.appGreenPale.opacity(0.1))
                                    .stroke(Color.appGreenDark.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
                        )
                        
                        // Answer Notes Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How did God answer? (Optional)")
                                .font(.headline)
                                .foregroundColor(.appGreenDark)
                            
                            Text("Share how you saw God work in this situation")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.appGreenPale.opacity(0.1))
                                    .stroke(Color.appGreenDark.opacity(0.3), lineWidth: 1)
                                    .frame(minHeight: 120)
                                
                                TextEditor(text: $answerNotes)
                                    .padding(8)
                                    .background(Color.clear)
                                    .font(.body)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
                        )
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Answer Prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.appGreenDark)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .foregroundColor(.appGreenDark)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

struct AnswerPrayerModal_Previews: PreviewProvider {
    static var previews: some View {
        AnswerPrayerModal(
            prayerRequest: PrayerRequest(
                title: "Healing for Mom",
                requestDescription: "Please pray for healing.",
                dateAdded: Date(),
                isAnswered: false
            ),
            answerDate: .constant(Date()),
            answerNotes: .constant("God provided healing and peace during this difficult time."),
            onSave: {},
            onCancel: {}
        )
        // NO .modelContainer() to avoid SwiftData crashes
    }
}
