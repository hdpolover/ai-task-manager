//
//  NLDemoView.swift
//  app_test
//
//  Demonstration View for Natural Language Processing Features
//

import SwiftUI

struct NLDemoView: View {
    @State private var inputText = ""
    @State private var analysisResult: NLProcessingResult?
    @State private var isAnalyzing = false
    @State private var showResults = false
    
    private let nlService = NaturalLanguageService()
    
    // Sample tasks for demonstration
    private let sampleTasks = [
        "Call the dentist tomorrow morning",
        "Buy groceries for dinner tonight",
        "Urgent: Finish project proposal by Friday",
        "Schedule a meeting with the client next week",
        "Book flight tickets for vacation in 2 weeks",
        "Quick email to Sarah about the budget",
        "Research new iPhone models maybe next month",
        "Workout at the gym this evening"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Natural Language AI")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Watch AI analyze and understand your tasks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enter a task:")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextEditor(text: $inputText)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    
                    // Sample Tasks
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Try these examples:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(sampleTasks, id: \.self) { task in
                                    Button(task) {
                                        inputText = task
                                        analyzeTask()
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Button("Analyze with AI") {
                        analyzeTask()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(inputText.isEmpty || isAnalyzing)
                    .padding(.horizontal)
                    
                    if isAnalyzing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("AI is analyzing...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Results Section
                if let result = analysisResult, showResults {
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("AI Analysis Results")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            // Due Date
                            AnalysisCard(
                                title: "Due Date",
                                icon: "calendar",
                                color: .blue,
                                content: {
                                    if let dueDate = result.extractedDueDate {
                                        Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                                            .fontWeight(.medium)
                                    } else {
                                        Text("No specific date found")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            )
                            
                            // Priority
                            AnalysisCard(
                                title: "Priority",
                                icon: "flag.fill",
                                color: Color.priorityColor(result.suggestedPriority),
                                content: {
                                    Text(result.suggestedPriority.rawValue)
                                        .fontWeight(.medium)
                                }
                            )
                            
                            // Category
                            AnalysisCard(
                                title: "Category",
                                icon: result.suggestedCategory.icon,
                                color: .orange,
                                content: {
                                    Text(result.suggestedCategory.rawValue)
                                        .fontWeight(.medium)
                                }
                            )
                            
                            // Duration
                            AnalysisCard(
                                title: "Estimated Duration",
                                icon: "clock",
                                color: .green,
                                content: {
                                    Text(formatDuration(result.estimatedDuration))
                                        .fontWeight(.medium)
                                }
                            )
                            
                            // Keywords
                            if !result.extractedKeywords.isEmpty {
                                AnalysisCard(
                                    title: "Keywords",
                                    icon: "tag",
                                    color: .purple,
                                    content: {
                                        LazyVGrid(columns: [
                                            GridItem(.adaptive(minimum: 80))
                                        ], spacing: 8) {
                                            ForEach(result.extractedKeywords, id: \.self) { keyword in
                                                Text(keyword)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.purple.opacity(0.1))
                                                    .cornerRadius(12)
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                )
                            }
                            
                            // Sentiment
                            AnalysisCard(
                                title: "Sentiment",
                                icon: "face.smiling",
                                color: result.sentimentScore > 0 ? .green : result.sentimentScore < 0 ? .red : .gray,
                                content: {
                                    HStack {
                                        Text(sentimentText(result.sentimentScore))
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text(String(format: "%.2f", result.sentimentScore))
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                }
                            )
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("NL Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func analyzeTask() {
        guard !inputText.isEmpty else { return }
        
        isAnalyzing = true
        showResults = false
        
        // Simulate processing delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            analysisResult = nlService.analyzeTaskText(inputText)
            isAnalyzing = false
            showResults = true
        }
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
    
    private func sentimentText(_ score: Double) -> String {
        if score > 0.1 {
            return "Positive"
        } else if score < -0.1 {
            return "Negative"
        } else {
            return "Neutral"
        }
    }
}

// MARK: - Analysis Card Component
struct AnalysisCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            content
        }
        .padding()
        .background(color.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

#Preview {
    NLDemoView()
}
