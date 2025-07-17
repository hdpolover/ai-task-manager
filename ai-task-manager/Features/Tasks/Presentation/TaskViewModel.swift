//
//  TaskViewModel.swift
//  ai-task-manager
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
    private let supabaseService: SupabaseServiceProtocol
    private let taskRepository: TaskRepositoryProtocol
    private let nlService: NaturalLanguageService
    
    // MARK: - Initialization
    init(dataManager: DataManagerProtocol = DIContainer.shared.getDataManager(), 
         supabaseService: SupabaseServiceProtocol = DIContainer.shared.getSupabaseService(),
         nlService: NaturalLanguageService = NaturalLanguageService()) {
        self.dataManager = dataManager
        self.supabaseService = supabaseService
        self.taskRepository = SupabaseTaskRepository(dataManager: dataManager, supabaseService: supabaseService)
        self.nlService = nlService
        loadTasks()
    }
    
    // MARK: - Task Management Functions
    func addTask(title: String, description: String, priority: TaskPriority? = nil, category: TaskCategory? = nil, dueDate: Date? = nil, estimatedDuration: TimeInterval? = nil, keywords: [String]? = nil) {
        isLoading = true
        errorMessage = nil
        
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
        
        // Add to local state immediately for responsive UI
        tasks.append(newTask)
        
        // Save to Supabase in background
        _Concurrency.Task {
            let success = await taskRepository.saveTask(newTask)
            
            await MainActor.run {
                self.isLoading = false
                if !success {
                    self.errorMessage = "Failed to save task to cloud. It's saved locally."
                    self.showingError = true
                }
            }
        }
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
        
        // Add to local state immediately
        tasks.append(newTask)
        
        // Save to Supabase in background
        _Concurrency.Task {
            let success = await taskRepository.saveTask(newTask)
            
            await MainActor.run {
                if !success {
                    self.errorMessage = "Failed to save task to cloud. It's saved locally."
                    self.showingError = true
                }
            }
        }
        
        return nlResult
    }
    
    func deleteTask(at offsets: IndexSet) {
        let tasksToDelete = offsets.map { tasks[$0] }
        
        // Remove from local state immediately
        tasks.remove(atOffsets: offsets)
        
        // Delete from Supabase in background
        _Concurrency.Task {
            for task in tasksToDelete {
                let success = await taskRepository.deleteTask(id: task.id)
                if !success {
                    await MainActor.run {
                        self.errorMessage = "Failed to delete task from cloud."
                        self.showingError = true
                    }
                }
            }
        }
    }
    
    func toggleTaskCompletion(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            let updatedTask = tasks[index]
            
            // Update in Supabase
            _Concurrency.Task {
                let success = await taskRepository.updateTask(updatedTask)
                if !success {
                    await MainActor.run {
                        self.errorMessage = "Failed to update task in cloud."
                        self.showingError = true
                    }
                }
            }
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
            
            let updatedTask = tasks[index]
            
            // Update in Supabase
            _Concurrency.Task {
                let success = await taskRepository.updateTask(updatedTask)
                if !success {
                    await MainActor.run {
                        self.errorMessage = "Failed to update task in cloud."
                        self.showingError = true
                    }
                }
            }
        }
    }
    
    // MARK: - Data Persistence
    func loadTasks() {
        isLoading = true
        errorMessage = nil
        
        _Concurrency.Task {
            do {
                let loadedTasks = await taskRepository.fetchTasks()
                await MainActor.run {
                    self.tasks = loadedTasks
                    self.isLoading = false
                }
            }
        }
    }
    
    func syncWithRemote() {
        isLoading = true
        errorMessage = nil
        
        _Concurrency.Task {
            let success = await dataManager.syncTasksWithRemote()
            
            await MainActor.run {
                if success {
                    self.loadTasks()
                } else {
                    self.errorMessage = "Failed to sync with cloud."
                    self.showingError = true
                    self.isLoading = false
                }
            }
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
