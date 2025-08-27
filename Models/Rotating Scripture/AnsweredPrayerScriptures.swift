//
//  AnsweredPrayerScriptures.swift
//  Christian Life Journal
//
//  Rotating scripture verses for prayer answered celebrations
//

import Foundation

struct AnsweredPrayerScripture {
    let reference: String
    let text: String
}

class AnsweredPrayerScriptureManager: ObservableObject {
    @Published var currentScripture: AnsweredPrayerScripture
    
    private let scriptures: [AnsweredPrayerScripture] = [
        AnsweredPrayerScripture(
            reference: "Isaiah 65:24",
            text: "Before they call I will answer; while they are yet speaking I will hear."
        ),
        AnsweredPrayerScripture(
            reference: "1 John 5:14-15",
            text: "And this is the confidence that we have toward him, that if we ask anything according to his will he hears us. And if we know that he hears us in whatever we ask, we know that we have the requests that we have asked of him."
        ),
        AnsweredPrayerScripture(
            reference: "Matthew 7:7",
            text: "Ask, and it will be given to you; seek, and you will find; knock, and it will be opened to you."
        ),
        AnsweredPrayerScripture(
            reference: "Jeremiah 33:3",
            text: "Call to me and I will answer you, and will tell you great and hidden things that you have not known."
        ),
        AnsweredPrayerScripture(
            reference: "Psalm 34:17",
            text: "When the righteous cry for help, the Lord hears and delivers them out of all their troubles."
        ),
        AnsweredPrayerScripture(
            reference: "James 5:16",
            text: "The prayer of a righteous person has great power as it is working."
        ),
        AnsweredPrayerScripture(
            reference: "Philippians 4:6-7",
            text: "Do not be anxious about anything, but in everything by prayer and supplication with thanksgiving let your requests be made known to God. And the peace of God, which surpasses all understanding, will guard your hearts and your minds in Christ Jesus."
        )
    ]
    
    private var lastUsedIndex: Int = -1
    
    init() {
        // Start with a random scripture
        let randomIndex = Int.random(in: 0..<scriptures.count)
        self.currentScripture = scriptures[randomIndex]
        self.lastUsedIndex = randomIndex
    }
    
    // Get the next scripture in rotation (cycles through all verses)
    func getNextScripture() -> AnsweredPrayerScripture {
        let nextIndex = (lastUsedIndex + 1) % scriptures.count
        lastUsedIndex = nextIndex
        currentScripture = scriptures[nextIndex]
        return currentScripture
    }
    
    // Get a random scripture (for immediate use without changing the rotation)
    func getRandomScripture() -> AnsweredPrayerScripture {
        let randomIndex = Int.random(in: 0..<scriptures.count)
        return scriptures[randomIndex]
    }
}