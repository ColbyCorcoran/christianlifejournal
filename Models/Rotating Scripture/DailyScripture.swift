//
//  DailyScripture.swift
//  Christian Life Journal
//
//  Rotating scripture verses for dashboard display
//

import Foundation

struct DailyScripture {
    let reference: String
    let text: String
}

class DailyScriptureManager: ObservableObject {
    @Published var currentScripture: DailyScripture
    
    private let scriptures: [DailyScripture] = [
        DailyScripture(
            reference: "Psalm 121:1-2",
            text: "I lift up my eyes to the hills. From where does my help come? My help comes from the LORD, who made heaven and earth."
        ),
        DailyScripture(
            reference: "Psalm 37:3-4",
            text: "Trust in the LORD, and do good; dwell in the land and befriend faithfulness. Delight yourself in the LORD, and he will give you the desires of your heart."
        ),
        DailyScripture(
            reference: "Proverbs 3:5-6",
            text: "Trust in the Lord with all your heart, and do not lean on your own understanding. In all your ways acknowledge him, and he will make straight your paths."
        ),
        DailyScripture(
            reference: "Isaiah 40:31",
            text: "but they who wait for the Lord shall renew their strength; they shall mount up with wings like eagles; they shall run and not be weary; they shall walk and not faint."
        ),
        DailyScripture(
            reference: "Matthew 11:28-30",
            text: "Come to me, all who labor and are heavy laden, and I will give you rest. Take my yoke upon you, and learn from me, for I am gentle and lowly in heart, and you will find rest for your souls. For my yoke is easy, and my burden is light."
        ),
        DailyScripture(
            reference: "Isaiah 57:15",
            text: "For thus says the One who is high and lifted up, who inhabits eternity, whose name is Holy: 'I dwell in the high and holy place, and also with him who is of a contrite and lowly spirit, to revive the spirit of the lowly, and to revive the heart of the contrite.'"
        )
    ]
    
    init() {
        // Get a consistent scripture for each app launch based on the current date
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % scriptures.count
        self.currentScripture = scriptures[index]
    }
    
    // Method to manually refresh scripture (for testing or manual refresh)
    func refreshScripture() {
        let randomIndex = Int.random(in: 0..<scriptures.count)
        currentScripture = scriptures[randomIndex]
    }
}
