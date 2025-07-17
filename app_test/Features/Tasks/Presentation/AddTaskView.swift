//
//  AddTaskView.swift
//  app_test
//
//  Modal View for Adding New Tasks
//

import SwiftUI

struct AddTaskView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedPriority = TaskPriority.medium
    @State private var selectedCategory = TaskCategory.general
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var estimatedDuration: TimeInterval = 1800 // 30 minutes default
    @State private var keywords: [String] = []
    
    // NL Analysis States
    @State private var nlAnalysisResult: NLProcessingResult?
    @State private var showNLSuggestions = false
    @State private var isAnalyzing = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task Title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: title) { _, _ in analyzeText() }
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                        .onChange(of: description) { _, _ in analyzeText() }
                    
                    if isAnalyzing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Analyzing with AI...")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                
                // NL Analysis Results Section
                if let nlResult = nlAnalysisResult, showNLSuggestions {
                    Section("AI Suggestions") {
                        VStack(alignment: .leading, spacing: 8) {
                            if let suggestedDate = nlResult.extractedDueDate {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                    Text("Suggested Due: \(suggestedDate.formatted(date: .abbreviated, time: .shortened))")
                                    Spacer()
                                    Button("Apply") {
                                        dueDate = suggestedDate
                                        hasDueDate = true
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            
                            HStack {
                                Image(systemName: "flag.fill")
                                    .foregroundColor(Color.priorityColor(nlResult.suggestedPriority))
                                Text("Suggested Priority: \(nlResult.suggestedPriority.rawValue)")
                                Spacer()
                                Button("Apply") {
                                    selectedPriority = nlResult.suggestedPriority
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            
                            HStack {
                                Image(systemName: nlResult.suggestedCategory.icon)
                                    .foregroundColor(.orange)
                                Text("Category: \(nlResult.suggestedCategory.rawValue)")
                                Spacer()
                                Button("Apply") {
                                    selectedCategory = nlResult.suggestedCategory
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.green)
                                Text("Estimated: \(formatDuration(nlResult.estimatedDuration))")
                                Spacer()
                                Button("Apply") {
                                    estimatedDuration = nlResult.estimatedDuration
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            
                            if !nlResult.extractedKeywords.isEmpty {
                                VStack(alignment: .leading) {
                                    Text("Keywords:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    ScrollView(.horizontal) {
                                        HStack {
                                            ForEach(nlResult.extractedKeywords, id: \.self) { keyword in
                                                Text(keyword)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.blue.opacity(0.1))
                                                    .cornerRadius(8)
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Button("Apply All Suggestions") {
                                applyAllSuggestions(nlResult)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                }
                
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(Color.priorityColor(priority))
                                    .frame(width: 12, height: 12)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Duration & Schedule") {
                    HStack {
                        Text("Estimated Duration:")
                        Spacer()
                        Text(formatDuration(estimatedDuration))
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $estimatedDuration, in: 300...14400, step: 300) // 5 min to 4 hours
                    
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("New Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        title.isNotEmpty && description.isNotEmpty
    }
    
    private func saveTask() {
        taskViewModel.addTask(
            title: title,
            description: description,
            priority: selectedPriority,
            category: selectedCategory,
            dueDate: hasDueDate ? dueDate : nil,
            estimatedDuration: estimatedDuration,
            keywords: keywords
        )
        dismiss()
    }
    
    // MARK: - Natural Language Processing Functions
    private func analyzeText() {
        guard !title.isEmpty else { 
            nlAnalysisResult = nil
            showNLSuggestions = false
            return 
        }
        
        isAnalyzing = true
        
        // Debounce the analysis to avoid too many calls
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let nlService = NaturalLanguageService()
            let combinedText = "\(title) \(description)"
            nlAnalysisResult = nlService.analyzeTaskText(combinedText)
            showNLSuggestions = true
            isAnalyzing = false
        }
    }
    
    private func applyAllSuggestions(_ nlResult: NLProcessingResult) {
        selectedPriority = nlResult.suggestedPriority
        selectedCategory = nlResult.suggestedCategory
        estimatedDuration = nlResult.estimatedDuration
        keywords = nlResult.extractedKeywords
        
        if let suggestedDate = nlResult.extractedDueDate {
            dueDate = suggestedDate
            hasDueDate = true
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
}

#Preview {
    AddTaskView(taskViewModel: TaskViewModel())
}
