//
//  SpeakerStore.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/19/25.
//

import SwiftUI

class SpeakerStore: ObservableObject {
    @Published var speakers: [String] = []

    func addSpeaker(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !speakers.contains(trimmed) else { return }
        speakers.append(trimmed)
    }

    func removeSpeaker(at index: Int) {
        guard speakers.indices.contains(index) else { return }
        speakers.remove(at: index)
    }

    func updateSpeaker(at index: Int, with name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard speakers.indices.contains(index), !trimmed.isEmpty else { return }
        speakers[index] = trimmed
    }
}

