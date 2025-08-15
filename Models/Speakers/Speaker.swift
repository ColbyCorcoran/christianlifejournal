//
//  Speaker.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 8/7/25.
//

import Foundation
import SwiftData

@Model
class Speaker {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
    
    // Required for SwiftData
    init() {
        self.id = UUID()
        self.name = ""
    }
    
    // MARK: - Preview Mock Creation
    static func previewSpeaker(name: String) -> Speaker {
        let speaker = Speaker()
        speaker.name = name
        return speaker
    }
}
