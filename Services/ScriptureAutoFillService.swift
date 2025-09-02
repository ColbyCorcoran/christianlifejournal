//
//  ScriptureAutoFillService.swift
//  Christian Life Journal
//
//  Created by Claude on 8/29/25.
//

import Foundation
import Combine

struct ScriptureReference {
    let book: String
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int?
    let originalText: String
    let range: NSRange  // Store the exact position in the original text
    
    var verseRange: String {
        if let end = verseEnd, end != verseStart {
            return "\(verseStart)-\(end)"
        }
        return "\(verseStart)"
    }
    
    var displayReference: String {
        return "\(book) \(chapter):\(verseRange)"
    }
}

class ScriptureAutoFillService: ObservableObject {
    private var bibleData: [String: [String: [String: String]]] = [:]
    private var settings: ScriptureAutoFillSettings
    
    private var currentTranslation: BibleTranslation = .kjv
    
    init(settings: ScriptureAutoFillSettings? = nil) {
        self.settings = settings ?? ScriptureAutoFillSettings.shared
        self.currentTranslation = self.settings.selectedTranslation
        loadBibleData()
    }
    
    private func checkAndReloadIfNeeded() {
        // Check if translation has changed since last load
        if currentTranslation != settings.selectedTranslation {
            currentTranslation = settings.selectedTranslation
            loadBibleData()
        }
    }
    
    private func loadBibleData() {
        // Clear existing data
        bibleData = [:]
        
        let fileName = settings.selectedTranslation.fileName
        guard let url = Bundle.main.url(forResource: settings.selectedTranslation.rawValue + "_bible", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: [String: String]]] else {
            print("Failed to load \(settings.selectedTranslation.displayName) Bible data from \(fileName)")
            return
        }
        bibleData = json
        print("✅ Loaded \(settings.selectedTranslation.displayName) Bible data")
    }
    
    func detectScriptureReferences(in text: String) -> [ScriptureReference] {
        // Return empty if auto-fill is disabled
        guard settings.isEnabled else { return [] }
        
        // Check if we need to reload data for translation changes
        checkAndReloadIfNeeded()
        // More precise pattern - limits book name to known Bible books
        let pattern = #"(?:^|\s)(\d?\s*(?:[A-Za-z]+\.?\s?){1,3}[A-Za-z]+\.?)\s+(\d+):(\d+)(?:-(\d+))?(?=\s|$|[^\w:])"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        var references: [ScriptureReference] = []
        
        print("🔍 DEBUG: Text='\(text)'")
        print("🔍 DEBUG: Pattern found \(matches.count) matches")
        
        for (index, match) in matches.enumerated() {
            guard let bookRange = Range(match.range(at: 1), in: text),
                  let chapterRange = Range(match.range(at: 2), in: text),
                  let verseRange = Range(match.range(at: 3), in: text),
                  let fullRange = Range(match.range, in: text) else { 
                continue 
            }
            
            let bookInput = String(text[bookRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let chapter = Int(String(text[chapterRange])) ?? 0
            let verseStart = Int(String(text[verseRange])) ?? 0
            
            var verseEnd: Int? = nil
            if match.range(at: 4).location != NSNotFound,
               let endRange = Range(match.range(at: 4), in: text) {
                verseEnd = Int(String(text[endRange]))
            }
            
            // Try to find the actual book name within the captured text
            let actualBookInput = extractBookFromCapturedText(bookInput)
            
            // Build the original text from the captured components using actual book name
            let chapterText = String(text[chapterRange])
            let verseText = String(text[verseRange])
            let originalText: String
            if let endVerse = verseEnd {
                originalText = "\(actualBookInput) \(chapterText):\(verseText)-\(endVerse)"
            } else {
                originalText = "\(actualBookInput) \(chapterText):\(verseText)"
            }
            
            print("📖 DEBUG Match \(index): fullMatch='\(String(text[fullRange]))', originalText='\(originalText)', book='\(bookInput)'")
            
            if let matchedBook = findMatchingBook(for: actualBookInput) {
                print("✅ DEBUG: Matched book '\(bookInput)' -> actualBook: '\(actualBookInput)' -> '\(matchedBook)'")
            } else {
                print("❌ DEBUG: No match for book '\(bookInput)' -> actualBook: '\(actualBookInput)'")
            }
            
            if let matchedBook = findMatchingBook(for: actualBookInput),
               isValidVerseReference(book: matchedBook, chapter: chapter, verseStart: verseStart, verseEnd: verseEnd) {
                // Calculate the exact range of just the scripture reference
                let fullMatch = String(text[fullRange])
                let referenceRange: NSRange
                
                // Find the actual book name within the full match
                if let bookRange = fullMatch.range(of: actualBookInput, options: .caseInsensitive) {
                    let bookStartOffset = fullMatch.distance(from: fullMatch.startIndex, to: bookRange.lowerBound)
                    referenceRange = NSRange(
                        location: match.range.location + bookStartOffset,
                        length: originalText.count
                    )
                } else {
                    // Fallback: find where alphanumeric content starts
                    if let bookStartIndex = fullMatch.firstIndex(where: { $0.isLetter || $0.isNumber }) {
                        let offset = fullMatch.distance(from: fullMatch.startIndex, to: bookStartIndex)
                        referenceRange = NSRange(
                            location: match.range.location + offset,
                            length: originalText.count
                        )
                    } else {
                        referenceRange = match.range
                    }
                }
                
                print("🎯 DEBUG: Range calculation - fullMatch='\(fullMatch)', referenceRange=\(referenceRange), originalText='\(originalText)'")
                
                let reference = ScriptureReference(
                    book: matchedBook,
                    chapter: chapter,
                    verseStart: verseStart,
                    verseEnd: verseEnd,
                    originalText: originalText,
                    range: referenceRange
                )
                references.append(reference)
            }
        }
        
        return references
    }
    
    private func extractBookFromCapturedText(_ capturedText: String) -> String {
        // If the captured text is too long, it likely includes extra words
        // Try to find the actual book name by checking each word combination from the end
        let words = capturedText.split(separator: " ").map(String.init)
        
        // Try different combinations, starting from the shortest (most likely to be a book)
        for length in 1...min(3, words.count) {
            let candidateWords = words.suffix(length)
            let candidate = candidateWords.joined(separator: " ")
            
            if findMatchingBook(for: candidate) != nil {
                print("🔍 DEBUG: Found book candidate '\(candidate)' from '\(capturedText)'")
                return candidate
            }
        }
        
        // If no match found, return the original
        return capturedText
    }
    
    private func isValidVerseReference(book: String, chapter: Int, verseStart: Int, verseEnd: Int?) -> Bool {
        // Check if the book and chapter exist in our Bible data
        guard let bookData = bibleData[book],
              let chapterData = bookData[String(chapter)] else {
            return false
        }
        
        // Check if verseStart exists
        guard chapterData[String(verseStart)] != nil else {
            return false
        }
        
        // If there's a verse range, check that verseEnd exists and is valid
        if let endVerse = verseEnd {
            guard endVerse > verseStart,
                  chapterData[String(endVerse)] != nil else {
                return false
            }
        }
        
        return true
    }
    
    private func findMatchingBook(for input: String) -> String? {
        let cleanInput = input.lowercased()
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // First try exact matches
        for book in bibleBooks {
            if book.name.lowercased() == cleanInput {
                return book.name
            }
            
            for abbreviation in book.abbreviations {
                let cleanAbbrev = abbreviation.lowercased().replacingOccurrences(of: ".", with: "")
                if cleanAbbrev == cleanInput {
                    return book.name
                }
            }
        }
        
        // Then try partial matches for common abbreviations
        for book in bibleBooks {
            for abbreviation in book.abbreviations {
                let cleanAbbrev = abbreviation.lowercased().replacingOccurrences(of: ".", with: "")
                if cleanAbbrev.hasPrefix(cleanInput) && cleanInput.count >= 3 {
                    return book.name
                }
            }
        }
        
        return nil
    }
    
    func lookupScriptureText(reference: ScriptureReference) -> String? {
        checkAndReloadIfNeeded()
        guard let book = bibleData[reference.book],
              let chapter = book[String(reference.chapter)] else {
            return nil
        }
        
        var verseTexts: [String] = []
        let endVerse = reference.verseEnd ?? reference.verseStart
        
        for verse in reference.verseStart...endVerse {
            if let verseText = chapter[String(verse)] {
                // Clean any existing quotation marks from individual verses (including Unicode smart quotes)
                let cleanedText = verseText
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"\u{201c}\u{201d}"))
                    .replacingOccurrences(of: "\u{201c}", with: "")
                    .replacingOccurrences(of: "\u{201d}", with: "")
                    .replacingOccurrences(of: "\u{2019}", with: "'")  // Convert smart apostrophe to regular apostrophe
                verseTexts.append(cleanedText)
            }
        }
        
        guard !verseTexts.isEmpty else { return nil }
        
        let combinedText = verseTexts.joined(separator: " ")
        return "\(reference.displayReference) - \"\(combinedText)\""
    }
    
    func processTextForAutoFill(_ text: String) -> String {
        // Return original text if auto-fill is disabled
        guard settings.isEnabled else { return text }
        let references = detectScriptureReferences(in: text)
        
        // Only process references that haven't been expanded yet
        let unexpandedReferences = references.filter { reference in
            // Check if this reference has already been expanded (contains " - "..." indicating verse text)
            let expandedPattern = "\(reference.displayReference) - \""
            return !text.contains(expandedPattern)
        }
        
        // Only auto-fill the LAST unexpanded reference (most recent one user typed)
        // This preserves cursor behavior and prevents reformatting existing text
        guard let lastReference = unexpandedReferences.last,
              let verseText = lookupScriptureText(reference: lastReference) else {
            return text
        }
        
        // Use NSString for precise range-based replacement
        let nsText = NSMutableString(string: text)
        
        // Convert the stored NSRange to use with NSMutableString
        let referenceRange = lastReference.range
        
        // Ensure the range is still valid in the current text
        if referenceRange.location != NSNotFound && 
           NSMaxRange(referenceRange) <= nsText.length {
            nsText.replaceCharacters(in: referenceRange, with: verseText)
        }
        
        return nsText as String
    }
    
    func getUnexpandedReferences(in text: String) -> [ScriptureReference] {
        // Return empty if auto-fill is disabled
        guard settings.isEnabled else { return [] }
        let allReferences = detectScriptureReferences(in: text)
        
        // Only return references that haven't been expanded yet
        let unexpanded = allReferences.filter { reference in
            let expandedPattern = "\(reference.displayReference) - "
            let isExpanded = text.contains(expandedPattern)
            return !isExpanded
        }
        
        return unexpanded
    }
    
    func hasScriptureReferences(in text: String) -> Bool {
        // Return false if auto-fill is disabled
        guard settings.isEnabled else { return false }
        return !detectScriptureReferences(in: text).isEmpty
    }
}