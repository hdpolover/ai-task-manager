//
//  TaskViewModel.swift
//  app_test
//
//  Clean Architecture - ViewModel Layer (MVVM Pattern)
//

import Foundation
import SwiftUI

// MARK: - Task View Model
@MainActor
class TaskViewModel: ObservableObject {
    // MARK: - Published Properties (State Management)
    @Published var tasks: [TaskItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    
    // MARK: - Dependencies
    private let dataManager: DataManagerProtocol
    private let networkService: NetworkService
    private let nlService: NaturalLanguageService
    
    // MARK: - Initialization
    init(dataManager: DataManagerProtocol = DataManager(), 
         networkService: NetworkService = NetworkService.shared,
         nlService: NaturalLanguageService = NaturalLanguageService()) {
        self.dataManager = dataManager
        self.networkService = networkService
        self.nlService = nlService
        loadTasks()
    }
    
    // MARK: - Task Management Functions
    func addTask(title: String, description: String, priority: TaskPriority? = nil, category: TaskCategory? = nil, dueDate: Date? = nil, estimatedDuration: TimeInterval? = nil, keywords: [String]? = nil) {
        // Use NL processing if values aren't explicitly provided
        let combinedText = "\(title) \(description)"
        let nlResult = nlService.analyzeTaskText(combinedText)
        
        let finalPriority = priority ?? nlResult.suggestedPriority
        let finalCategory = category ?? nlResult.suggestedCategory
        let finalDueDate = dueDate ?? nlResult.extractedDueDate
        let finalDuration = estimatedDuration ?? nlResult.estimatedDuration
        let finalKeywords = keywords ?? nlResult.extractedKeywords
        
        let newTask = TaskItem(
            title: title,
            description: description,
            priority: finalPriority,
            category: finalCategory,
            dueDate: finalDueDate,
            estimatedDuration: finalDuration,
            keywords: finalKeywords
        )
        
        tasks.append(newTask)
        saveTasks()
    }
    
    // Enhanced version with NL analysis
    func addTaskWithNLAnalysis(title: String, description: String) -> NLProcessingResult {
        let combinedText = "\(title) \(description)"
        let nlResult = nlService.analyzeTaskText(combinedText)
        
        let newTask = TaskItem(
            title: title,
            description: description,
            priority: nlResult.suggestedPriority,
            category: nlResult.suggestedCategory,
            dueDate: nlResult.extractedDueDate,
            estimatedDuration: nlResult.estimatedDuration,
            keywords: nlResult.extractedKeywords
        )
        
        tasks.append(newTask)
        saveTasks()
        
        return nlResult
    }
    
    func deleteTask(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        saveTasks()
    }
    
    func toggleTaskCompletion(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveTasks()
        }
    }
    
    func updateTask(_ task: TaskItem, title: String, description: String, priority: TaskPriority, category: TaskCategory, dueDate: Date?, estimatedDuration: TimeInterval, keywords: [String]) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].title = title
            tasks[index].description = description
            tasks[index].priority = priority
            tasks[index].category = category
            tasks[index].dueDate = dueDate
            tasks[index].estimatedDuration = estimatedDuration
            tasks[index].keywords = keywords
            saveTasks()
        }
    }
    
    // MARK: - Data Persistence
    private func saveTasks() {
        _Concurrency.Task {
            let success = await dataManager.saveTasks(tasks)
            if !success {
                handleError(DataError.saveFailed)
            }
        }
    }
    
    private func loadTasks() {
        _Concurrency.Task {
            isLoading = true
            tasks = await dataManager.loadTasks()
            isLoading = false
        }
    }
    
    // MARK: - Network Operations
    func refreshFromNetwork() {
        _Concurrency.Task {
            isLoading = true
            do {
                let remoteTasks = try await networkService.fetchRemoteData()
                // Merge with existing tasks (avoid duplicates)
                for remoteTask in remoteTasks {
                    if !tasks.contains(where: { $0.title == remoteTask.title }) {
                        tasks.append(remoteTask)
                    }
                }
                let success = await dataManager.saveTasks(tasks)
                if !success {
                    handleError(DataError.saveFailed)
                }
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }
    
    // MARK: - Computed Properties
    var completedTasks: [TaskItem] {
        tasks.filter { $0.isCompleted }
    }
    
    var pendingTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }
    }
    
    var highPriorityTasks: [TaskItem] {
        tasks.filter { $0.priority == .high }
    }
    
    var tasksByCategory: [TaskCategory: [TaskItem]] {
        Dictionary(grouping: tasks) { $0.category }
    }
    
    var totalEstimatedTime: TimeInterval {
        pendingTasks.reduce(0) { $0 + $1.estimatedDuration }
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
}
