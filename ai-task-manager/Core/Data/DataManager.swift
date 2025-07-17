//
//  DataManager.swift
//  ai-task-manager
//
//  Clean Architecture - Service Layer (Data Persistence)
//

import Foundation

// MARK: - Data Manager Protocol
protocol DataManagerProtocol {
    func saveUsers(_ users: [User]) async -> Bool
    func loadUsers() async -> [User]
    func saveTasks(_ tasks: [TaskItem]) async -> Bool
    func loadTasks() async -> [TaskItem]
}

// MARK: - Data Manager Implementation
class DataManager: DataManagerProtocol {
    private let userDefaults = UserDefaults.standard
    private let usersKey = "SavedUsers"
    private let tasksKey = "SavedTasks"
    
    // MARK: - User Data Management
    func saveUsers(_ users: [User]) async -> Bool {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(users)
            userDefaults.set(data, forKey: usersKey)
            return true
        } catch {
            print("Error saving users: \(error)")
            return false
        }
    }
    
    func loadUsers() async -> [User] {
        guard let data = userDefaults.data(forKey: usersKey) else {
            return []
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([User].self, from: data)
        } catch {
            print("Error loading users: \(error)")
            return []
        }
    }
    
    // MARK: - Task Data Management
    func saveTasks(_ tasks: [TaskItem]) async -> Bool {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(tasks)
            userDefaults.set(data, forKey: tasksKey)
            return true
        } catch {
            print("Error saving tasks: \(error)")
            return false
        }
    }
    
    func loadTasks() async -> [TaskItem] {
        guard let data = userDefaults.data(forKey: tasksKey) else {
            return []
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([TaskItem].self, from: data)
        } catch {
            print("Error loading tasks (likely due to model changes): \(error)")
            // Clear corrupted data and return empty array
            userDefaults.removeObject(forKey: tasksKey)
            return []
        }
    }
}

// MARK: - Network Service (Simulated)
class NetworkService: ObservableObject {
    static let shared = NetworkService()
    
    private init() {}
    
    // Simulate network delay and potential failure
    func fetchRemoteData() async throws -> [TaskItem] {
        // Simulate network delay using Swift's Task.sleep (not our TaskItem model)
        try await _Concurrency.Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Simulate potential network failure (10% chance)
        if Double.random(in: 0...1) < 0.1 {
            throw DataNetworkError.connectionFailed
        }
        
        // Return mock data
        return [
            TaskItem(title: "Remote Task 1", description: "This task came from a simulated API", priority: .high, category: .work),
            TaskItem(title: "Remote Task 2", description: "Another remote task", priority: .medium, category: .general)
        ]
    }
}

// MARK: - Network Errors (renamed to avoid conflicts)
enum DataNetworkError: LocalizedError {
    case connectionFailed
    case invalidData
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to server"
        case .invalidData:
            return "Invalid data received"
        case .serverError:
            return "Server error occurred"
        }
    }
}
