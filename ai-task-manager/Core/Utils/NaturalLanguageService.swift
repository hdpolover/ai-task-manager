//
//  NaturalLanguageService.swift
//  ai-task-manager
//
//  Natural Language Processing Service for Task Creation
//

import Foundation
import NaturalLanguage

// MARK: - Natural Language Processing Result
struct NLProcessingResult {
    let extractedDueDate: Date?
    let suggestedPriority: TaskPriority
    let suggestedCategory: TaskCategory
    let estimatedDuration: TimeInterval
    let extractedKeywords: [String]
    let sentimentScore: Double // -1.0 to 1.0 (negative to positive)
}

// MARK: - Natural Language Service
class NaturalLanguageService {
    private let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass, .sentimentScore])
    private let calendar = Calendar.current
    
    // MARK: - Main Processing Function
    func analyzeTaskText(_ text: String) -> NLProcessingResult {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return NLProcessingResult(
            extractedDueDate: extractDueDate(from: cleanText),
            suggestedPriority: determinePriority(from: cleanText),
            suggestedCategory: categorizeTask(from: cleanText),
            estimatedDuration: estimateTaskDuration(from: cleanText),
            extractedKeywords: extractKeywords(from: cleanText),
            sentimentScore: analyzeSentiment(from: cleanText)
        )
    }
    
    // MARK: - Due Date Extraction
    func extractDueDate(from text: String) -> Date? {
        let lowercaseText = text.lowercased()
        let now = Date()
        
        // Today patterns
        if lowercaseText.contains("today") || lowercaseText.contains("tonight") {
            if lowercaseText.contains("morning") {
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)
            } else if lowercaseText.contains("afternoon") {
                return calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now)
            } else if lowercaseText.contains("evening") || lowercaseText.contains("tonight") {
                return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now)
            }
            return now
        }
        
        // Tomorrow patterns
        if lowercaseText.contains("tomorrow") {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            if lowercaseText.contains("morning") {
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)
            } else if lowercaseText.contains("afternoon") {
                return calendar.date(bySettingHour: 14, minute: 0, second: 0, of: tomorrow)
            }
            return tomorrow
        }
        
        // Day of week patterns
        let weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        for (index, day) in weekdays.enumerated() {
            if lowercaseText.contains(day) {
                return getNextWeekday(index + 1) // Calendar weekday starts from 1 (Sunday)
            }
        }
        
        // Relative time patterns
        if lowercaseText.contains("next week") {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: now)
        }
        
        if lowercaseText.contains("next month") {
            return calendar.date(byAdding: .month, value: 1, to: now)
        }
        
        // Number patterns (in X days/weeks/months)
        let patterns = [
            ("in (\\d+) days?", Calendar.Component.day),
            ("in (\\d+) weeks?", Calendar.Component.weekOfYear),
            ("in (\\d+) months?", Calendar.Component.month)
        ]
        
        for (pattern, component) in patterns {
            if let match = text.range(of: pattern, options: .regularExpression),
               let numberString = extractNumber(from: String(text[match])),
               let number = Int(numberString) {
                return calendar.date(byAdding: component, value: number, to: now)
            }
        }
        
        return nil
    }
    
    // MARK: - Priority Detection
    func determinePriority(from text: String) -> TaskPriority {
        let lowercaseText = text.lowercased()
        
        // High priority keywords
        let highPriorityWords = ["urgent", "asap", "immediately", "critical", "important", "emergency", "deadline", "due today"]
        if highPriorityWords.contains(where: lowercaseText.contains) {
            return .high
        }
        
        // Low priority keywords
        let lowPriorityWords = ["maybe", "sometime", "eventually", "when free", "optional", "nice to have"]
        if lowPriorityWords.contains(where: lowercaseText.contains) {
            return .low
        }
        
        // Check for exclamation marks (indicates urgency)
        if text.contains("!") {
            return .high
        }
        
        return .medium // Default priority
    }
    
    // MARK: - Task Categorization
    func categorizeTask(from text: String) -> TaskCategory {
        let lowercaseText = text.lowercased()
        
        // Meeting keywords
        let meetingWords = ["meeting", "call", "conference", "interview", "appointment", "presentation", "discussion"]
        if meetingWords.contains(where: lowercaseText.contains) {
            return .meeting
        }
        
        // Shopping keywords
        let shoppingWords = ["buy", "purchase", "shop", "grocery", "store", "mall", "order", "amazon"]
        if shoppingWords.contains(where: lowercaseText.contains) {
            return .shopping
        }
        
        // Work keywords
        let workWords = ["project", "report", "document", "client", "office", "deadline", "proposal", "email"]
        if workWords.contains(where: lowercaseText.contains) {
            return .work
        }
        
        // Health keywords
        let healthWords = ["doctor", "dentist", "hospital", "gym", "workout", "exercise", "medical", "appointment"]
        if healthWords.contains(where: lowercaseText.contains) {
            return .health
        }
        
        // Finance keywords
        let financeWords = ["bank", "payment", "bill", "budget", "money", "finance", "investment", "tax"]
        if financeWords.contains(where: lowercaseText.contains) {
            return .finance
        }
        
        // Travel keywords
        let travelWords = ["flight", "hotel", "vacation", "trip", "travel", "booking", "airport", "passport"]
        if travelWords.contains(where: lowercaseText.contains) {
            return .travel
        }
        
        return .general
    }
    
    // MARK: - Duration Estimation
    func estimateTaskDuration(from text: String) -> TimeInterval {
        let lowercaseText = text.lowercased()
        
        // Quick tasks (15 minutes)
        let quickWords = ["quick", "brief", "short", "email", "call", "text", "message"]
        if quickWords.contains(where: lowercaseText.contains) {
            return 15 * 60
        }
        
        // Long tasks (2+ hours)
        let longWords = ["project", "research", "write", "document", "report", "presentation", "plan"]
        if longWords.contains(where: lowercaseText.contains) {
            return 2 * 60 * 60
        }
        
        // Medium tasks (1 hour)
        let mediumWords = ["meeting", "appointment", "grocery", "shopping", "workout"]
        if mediumWords.contains(where: lowercaseText.contains) {
            return 60 * 60
        }
        
        // Extract explicit time mentions
        if let match = text.range(of: "(\\d+)\\s*(minutes?|mins?)", options: .regularExpression),
           let numberString = extractNumber(from: String(text[match])),
           let minutes = Int(numberString) {
            return Double(minutes * 60)
        }
        
        if let match = text.range(of: "(\\d+)\\s*(hours?|hrs?)", options: .regularExpression),
           let numberString = extractNumber(from: String(text[match])),
           let hours = Int(numberString) {
            return Double(hours * 60 * 60)
        }
        
        return 30 * 60 // Default 30 minutes
    }
    
    // MARK: - Keyword Extraction
    func extractKeywords(from text: String) -> [String] {
        tagger.string = text
        var keywords: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if let tag = tag, tag == .noun || tag == .verb {
                let word = String(text[tokenRange]).lowercased()
                if word.count > 3 && !isCommonWord(word) {
                    keywords.append(word)
                }
            }
            return true
        }
        
        return Array(Set(keywords)).prefix(5).map { $0 } // Return unique keywords, max 5
    }
    
    // MARK: - Sentiment Analysis
    func analyzeSentiment(from text: String) -> Double {
        tagger.string = text
        var sentimentScore: Double = 0.0
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .paragraph, scheme: .sentimentScore) { tag, _ in
            if let tag = tag, let score = Double(tag.rawValue) {
                sentimentScore = score
            }
            return true
        }
        
        return sentimentScore
    }
    
    // MARK: - Helper Functions
    private func getNextWeekday(_ targetWeekday: Int) -> Date {
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        var daysToAdd = targetWeekday - currentWeekday
        
        if daysToAdd <= 0 {
            daysToAdd += 7 // Next week
        }
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: now) ?? now
    }
    
    private func extractNumber(from text: String) -> String? {
        let pattern = "\\d+"
        if let match = text.range(of: pattern, options: .regularExpression) {
            return String(text[match])
        }
        return nil
    }
    
    private func isCommonWord(_ word: String) -> Bool {
        let commonWords = ["the", "and", "for", "are", "but", "not", "you", "all", "can", "had", "her", "was", "one", "our", "out", "day", "get", "has", "him", "his", "how", "its", "may", "new", "now", "old", "see", "two", "way", "who", "boy", "did", "man", "try"]
        return commonWords.contains(word)
    }
}
