//
//  PrayerRequestStore.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/11/25.
//

import SwiftUI
import SwiftData

class PrayerRequestStore: ObservableObject {
    @Published var prayerRequests: [PrayerRequest] = []
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Only refresh if not in preview mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            refresh()
        }
    }
    
    // MARK: - Data Management
    
    func refresh() {
        let descriptor = FetchDescriptor<PrayerRequest>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        
        do {
            prayerRequests = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching prayer requests: \(error)")
            prayerRequests = []
        }
    }
    
    // MARK: - CRUD Operations
    
    func addPrayerRequest(_ prayerRequest: PrayerRequest) {
        modelContext.insert(prayerRequest)
        
        do {
            try modelContext.save()
            refresh()
        } catch {
            print("Error adding prayer request: \(error)")
        }
    }
    
    func updatePrayerRequest(_ prayerRequest: PrayerRequest) {
        do {
            try modelContext.save()
            refresh()
        } catch {
            print("Error updating prayer request: \(error)")
        }
    }
    
    func removePrayerRequest(withId id: UUID) {
        guard let prayerRequest = prayerRequests.first(where: { $0.id == id }) else { return }
        
        modelContext.delete(prayerRequest)
        
        do {
            try modelContext.save()
            refresh()
        } catch {
            print("Error removing prayer request: \(error)")
        }
    }
    
    func markAsAnswered(_ prayerRequest: PrayerRequest, answerDate: Date = Date(), answerNotes: String? = nil) {
        prayerRequest.isAnswered = true
        prayerRequest.dateAnswered = answerDate
        prayerRequest.answerNotes = answerNotes
        
        updatePrayerRequest(prayerRequest)
    }
    
    func markAsUnanswered(_ prayerRequest: PrayerRequest) {
        prayerRequest.isAnswered = false
        prayerRequest.dateAnswered = nil
        prayerRequest.answerNotes = nil
        
        updatePrayerRequest(prayerRequest)
    }
    
    // MARK: - Statistics & Filtering
    
    var activePrayerRequests: [PrayerRequest] {
        prayerRequests.filter { !$0.isAnswered }
    }
    
    var answeredPrayerRequests: [PrayerRequest] {
        prayerRequests.filter { $0.isAnswered }
    }
    
    var recentlyAnsweredRequests: [PrayerRequest] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return answeredPrayerRequests.filter { request in
            guard let answerDate = request.dateAnswered else { return false }
            return answerDate >= thirtyDaysAgo
        }
    }
    
    func prayerRequests(for categoryID: UUID?) -> [PrayerRequest] {
        guard let categoryID = categoryID else {
            return prayerRequests.filter { $0.categoryIDs.isEmpty }
        }
        return prayerRequests.filter { $0.categoryIDs.contains(categoryID) }
    }
    
    func prayerRequests(withTagID tagID: UUID) -> [PrayerRequest] {
        return prayerRequests.filter { $0.tagIDs.contains(tagID) }
    }
    
    // MARK: - Statistics
    
    var totalActiveRequests: Int {
        activePrayerRequests.count
    }
    
    var totalAnsweredRequests: Int {
        answeredPrayerRequests.count
    }
    
    var recentlyAnsweredCount: Int {
        recentlyAnsweredRequests.count
    }
}

