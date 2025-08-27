//
//  PrayerAnsweredCelebrationView.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/11/25.
//

import SwiftUI

struct PrayerAnsweredCelebrationView: View {
    let prayerRequest: PrayerRequest
    @Binding var isPresented: Bool
    
    @State private var showContent = false
    @State private var scale: CGFloat = 0.8
    @State private var celebrationScripture: AnsweredPrayerScripture
    
    init(prayerRequest: PrayerRequest, isPresented: Binding<Bool>) {
        self.prayerRequest = prayerRequest
        self._isPresented = isPresented
        // Get a random scripture for this celebration
        self._celebrationScripture = State(initialValue: AnsweredPrayerScriptureManager().getRandomScripture())
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Celebration Card
            VStack(spacing: 20) {
                // Celebration Animation
                VStack(spacing: 16) {
                    Image(systemName: "hands.and.sparkles.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                        .scaleEffect(showContent ? 1.0 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0), value: showContent)
                    
                    Text("Praise God!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.appGreenDark)
                        .opacity(showContent ? 1.0 : 0)
                        .animation(.easeInOut(duration: 0.5).delay(0.2), value: showContent)
                    
                    Text("He has answered your prayer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1.0 : 0)
                        .animation(.easeInOut(duration: 0.5).delay(0.4), value: showContent)
                }
                
                // Prayer Details
                VStack(spacing: 12) {
                    Text("\(prayerRequest.title)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1.0 : 0)
                        .animation(.easeInOut(duration: 0.5).delay(0.6), value: showContent)
                    
                    if let daysPrayed = prayerRequest.daysPrayedFor {
                        Text("Prayed for \(daysPrayed) \(daysPrayed == 1 ? "day" : "days")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .opacity(showContent ? 1.0 : 0)
                            .animation(.easeInOut(duration: 0.5).delay(0.8), value: showContent)
                    }
                }
                .padding(.horizontal)
                
                // Bible Verse
                VStack(spacing: 8) {
                    Text(celebrationScripture.text)
                        .font(.body)
                        .italic()
                        .foregroundColor(.appGreenDark)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1.0 : 0)
                        .animation(.easeInOut(duration: 0.5).delay(1.0), value: showContent)
                    
                    Text(celebrationScripture.reference)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.appGreenMedium)
                        .opacity(showContent ? 1.0 : 0)
                        .animation(.easeInOut(duration: 0.5).delay(1.2), value: showContent)
                }
                .padding(.horizontal)
                
                // Close Button
                Button(action: dismissCelebration) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.appGreenDark)
                        )
                }
                .buttonStyle(.plain)
                .opacity(showContent ? 1.0 : 0)
                .animation(.easeInOut(duration: 0.5).delay(1.4), value: showContent)
                .padding(.horizontal)
            }
            .padding(24)
            .frame(width: 320)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appWhite)
                    .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
            )
            .scaleEffect(scale)
            .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: scale)
        }
        .onAppear {
            showContent = true
            scale = 1.0
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 0.8
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Preview

struct PrayerAnsweredCelebrationView_Previews: PreviewProvider {
    static var previews: some View {
        PrayerAnsweredCelebrationView(
            prayerRequest: PrayerRequest(
                title: "Healing for Mom",
                requestDescription: "Please pray for healing.",
                dateAdded: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
                isAnswered: true,
                dateAnswered: Date()
            ),
            isPresented: .constant(true)
        )
        // NO .modelContainer() to avoid SwiftData crashes
    }
}
