//
//  DataManager.swift
//  ai-task-manager
//
//  Clean Architecture - Service Layer (Data Persistence)
//

import Foundation

// MARK: - Data Manager Protocol
protocol DataManagerProtocol {
    // User Profile (Single User)
    func saveUserProfile(_ profile: UserProfile) async -> Bool
    func loadUserProfile() async -> UserProfile?
    
    // Tasks (Local + Remote)
    func saveTasks(_ tasks: [TaskItem]) async -> Bool
    func loadTasks() async -> [TaskItem]
    func syncTasksWithRemote() async -> Bool
    
    // Legacy support (deprecated)
    @available(*, deprecated, message: "Use saveUserProfile instead")
    func saveUsers(_ users: [User]) async -> Bool
    @available(*, deprecated, message: "Use loadUserProfile instead")
    func loadUsers() async -> [User]
}

// MARK: - Data Manager Implementation
class DataManager: DataManagerProtocol {
    private let userDefaults = UserDefaults.standard
    private let usersKey = "SavedUsers"
    private let tasksKey = "SavedTasks"
    private let userProfileKey = "UserProfile"
    private let supabaseService: SupabaseServiceProtocol
    
    init(supabaseService: SupabaseServiceProtocol = MockSupabaseService()) {
        self.supabaseService = supabaseService
    }
    
    // MARK: - User Profile Management
    func saveUserProfile(_ profile: UserProfile) async -> Bool {
        do {
            // Save to local storage first
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            userDefaults.set(data, forKey: userProfileKey)
            
            // Try to sync with Supabase
            do {
                _ = try await supabaseService.updateUserProfile(profile)
            } catch {
                print("Failed to sync user profile with remote: \(error)")
                // Continue with local save even if remote fails
            }
            
            return true
        } catch {
            print("Error saving user profile: \(error)")
            return false
        }
    }
    
    func loadUserProfile() async -> UserProfile? {
        // Try to load from remote first
        do {
            if let remoteProfile = try await supabaseService.getUserProfile() {
                // Save to local cache
                let encoder = JSONEncoder()
                if let data = try? encoder.encode(remoteProfile) {
                    userDefaults.set(data, forKey: userProfileKey)
                }
                return remoteProfile
            }
        } catch {
            print("Failed to load user profile from remote: \(error)")
        }
        
        // Fallback to local storage
        guard let data = userDefaults.data(forKey: userProfileKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(UserProfile.self, from: data)
        } catch {
            print("Error loading user profile: \(error)")
            return nil
        }
    }
    
    // MARK: - Task Data Management with Sync
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
        // Try to load from remote first for fresh data
        do {
            let remoteTasks = try await supabaseService.getTasks()
            // Cache remotely loaded tasks locally
            await saveTasks(remoteTasks)
            return remoteTasks
        } catch {
            print("Failed to load tasks from remote: \(error)")
        }
        
        // Fallback to local storage
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
    
    func syncTasksWithRemote() async -> Bool {
        do {
            let remoteTasks = try await supabaseService.getTasks()
            return await saveTasks(remoteTasks)
        } catch {
            print("Failed to sync tasks with remote: \(error)")
            return false
        }
    }
    
    // MARK: - Legacy Methods (Deprecated)
    @available(*, deprecated, message: "Use saveUserProfile instead")
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
    
    @available(*, deprecated, message: "Use loadUserProfile instead")
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
}
