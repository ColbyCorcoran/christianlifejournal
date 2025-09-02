//
//  ScriptureAutoFillSettings.swift
//  Christian Life Journal
//
//  Created by Claude on 8/29/25.
//

import Foundation
import Combine

enum BibleTranslation: String, CaseIterable {
    case kjv = "KJV"
    case esv = "ESV"
    
    var displayName: String {
        switch self {
        case .kjv:
            return "King James Version (KJV)"
        case .esv:
            return "English Standard Version (ESV)"
        }
    }
    
    var fileName: String {
        return "\(rawValue.lowercased())_bible.json"
    }
    
    var abbreviation: String {
        return rawValue
    }
}

class ScriptureAutoFillSettings: ObservableObject {
    static let shared = ScriptureAutoFillSettings()
    
    // Direct reference to CloudKit settings - no circular binding needed
    var isEnabled: Bool {
        get { CloudKitSettingsService.shared.scriptureAutoFillEnabled }
        set { CloudKitSettingsService.shared.scriptureAutoFillEnabled = newValue }
    }
    
    var selectedTranslation: BibleTranslation {
        get { CloudKitSettingsService.shared.selectedTranslation }
        set { CloudKitSettingsService.shared.selectedTranslation = newValue }
    }
    
    // For views that need to observe changes
    var objectWillChange: AnyPublisher<Void, Never> {
        Publishers.Merge(
            CloudKitSettingsService.shared.$scriptureAutoFillEnabled.map { _ in () },
            CloudKitSettingsService.shared.$selectedTranslation.map { _ in () }
        )
        .eraseToAnyPublisher()
    }
    
    private init() {
        // Simple initialization - no complex binding needed
    }
}
