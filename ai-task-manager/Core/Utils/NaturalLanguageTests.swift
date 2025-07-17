//
//  NaturalLanguageTests.swift
//  ai-task-manager
//
//  Test file for Natural Language Service
//

import Foundation

// MARK: - Simple Test Function
func testNaturalLanguageService() {
    let nlService = NaturalLanguageService()
    
    // Test cases
    let testCases = [
        "Call the dentist tomorrow morning",
        "Buy groceries for dinner tonight", 
        "Urgent: Finish project proposal by Friday",
        "Schedule a meeting with the client next week",
        "Quick email to Sarah"
    ]
    
    print("🧪 Testing Natural Language Service")
    print("=====================================")
    
    for (index, testCase) in testCases.enumerated() {
        print("\n🔍 Test Case \(index + 1): \"\(testCase)\"")
        
        let result = nlService.analyzeTaskText(testCase)
        
        // Print results
        print("   📅 Due Date: \(result.extractedDueDate?.formatted() ?? "None")")
        print("   🚩 Priority: \(result.suggestedPriority.rawValue)")
        print("   📂 Category: \(result.suggestedCategory.rawValue)")
        print("   ⏱️ Duration: \(formatDuration(result.estimatedDuration))")
        print("   🏷️ Keywords: \(result.extractedKeywords.joined(separator: ", "))")
        print("   😊 Sentiment: \(String(format: "%.2f", result.sentimentScore))")
    }
    
    print("\n✅ Natural Language Service testing completed!")
}

private func formatDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = Int(duration) % 3600 / 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}
