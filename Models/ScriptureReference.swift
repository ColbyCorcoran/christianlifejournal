//
//  ScriptureReference.swift
//  Christian Life Journal
//
//  Created by Colby Corcoran on 7/11/25.
//

import Foundation

struct ScriptureReference: Identifiable, Equatable {
    let id = UUID()
    let book: String
    let chapter: Int?
    let verse: Int?
    let verseEnd: Int?
    let raw: String
    let isValid: Bool
    let error: String?
}

func parseScriptureReference(_ input: String, bibleBooks: [BibleBook]) -> ScriptureReference? {
    let trimmed = input.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return nil }

    // Regex: Book name (up to the last digit), chapter, optional :verse, optional -verseEnd
    // The key is the lookahead: match book name up to the last space before the chapter number
    let pattern = #"^([1-3]?\s?[A-Za-z ]*?)(?=\d)\s*(\d+)(?::(\d+)(?:-(\d+))?)?$"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
    let nsrange = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
    guard let match = regex.firstMatch(in: trimmed, options: [], range: nsrange) else {
        return ScriptureReference(book: "", chapter: nil, verse: nil, verseEnd: nil, raw: input, isValid: false, error: "Format not recognized")
    }

    // Extract book, chapter, verse, verseEnd
    let bookRange = Range(match.range(at: 1), in: trimmed)
    let chapterRange = Range(match.range(at: 2), in: trimmed)
    let verseRange = Range(match.range(at: 3), in: trimmed)
    let verseEndRange = Range(match.range(at: 4), in: trimmed)

    let book = bookRange.map { String(trimmed[$0]).trimmingCharacters(in: .whitespaces) } ?? ""
    let chapter = chapterRange.flatMap { Int(trimmed[$0]) }
    let verse = verseRange.flatMap { Int(trimmed[$0]) }
    let verseEnd = verseEndRange.flatMap { Int(trimmed[$0]) }

    // If the input ends with a colon or dash, treat as incomplete (not valid yet)
    if trimmed.last == ":" || trimmed.last == "-" {
        return ScriptureReference(book: book, chapter: chapter, verse: verse, verseEnd: verseEnd, raw: input, isValid: false, error: nil)
    }

    // Book lookup (case-insensitive, supports abbreviations)
    let foundBook = bibleBooks.first { b in
        b.name.lowercased() == book.lowercased() ||
        b.abbreviations.map { $0.lowercased() }.contains(book.lowercased())
    }

    guard let bookObj = foundBook else {
        return ScriptureReference(book: book, chapter: chapter, verse: verse, verseEnd: verseEnd, raw: input, isValid: false, error: "Book not found")
    }

    // Validate chapter
    guard let ch = chapter, ch >= 1, ch <= bookObj.chapters.count else {
        return ScriptureReference(book: bookObj.name, chapter: chapter, verse: verse, verseEnd: verseEnd, raw: input, isValid: false, error: "Invalid chapter")
    }

    // If a colon is present but no verse, treat as incomplete
    if trimmed.contains(":"), verse == nil {
        return ScriptureReference(book: bookObj.name, chapter: chapter, verse: nil, verseEnd: nil, raw: input, isValid: false, error: nil)
    }

    // Validate verse(s) if present
    let maxVerse = bookObj.chapters[ch - 1]
    if let v = verse, v < 1 || v > maxVerse {
        return ScriptureReference(book: bookObj.name, chapter: chapter, verse: verse, verseEnd: verseEnd, raw: input, isValid: false, error: "Invalid verse")
    }
    if let vStart = verse, let vEnd = verseEnd, vEnd < vStart || vEnd > maxVerse {
        return ScriptureReference(book: bookObj.name, chapter: chapter, verse: verse, verseEnd: verseEnd, raw: input, isValid: false, error: "Invalid verse range")
    }

    return ScriptureReference(book: bookObj.name, chapter: chapter, verse: verse, verseEnd: verseEnd, raw: input, isValid: true, error: nil)
}
