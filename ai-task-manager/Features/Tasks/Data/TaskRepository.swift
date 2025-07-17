import Foundation

// MARK: - Task Repository Protocol
protocol TaskRepositoryProtocol {
    func fetchTasks() async -> [TaskItem]
    func saveTask(_ task: TaskItem) async -> Bool
    func updateTask(_ task: TaskItem) async -> Bool
    func deleteTask(id: UUID) async -> Bool
    func toggleTaskCompletion(id: UUID) async -> Bool
}

// MARK: - Local Task Repository Implementation
class LocalTaskRepository: TaskRepositoryProtocol {
    private let dataManager: DataManagerProtocol
    private let cacheKey = "tasks"
    
    init(dataManager: DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    func fetchTasks() async -> [TaskItem] {
        return await dataManager.loadTasks()
    }
    
    func saveTask(_ task: TaskItem) async -> Bool {
        var currentTasks = await fetchTasks()
        currentTasks.append(task)
        return await dataManager.saveTasks(currentTasks)
    }
    
    func updateTask(_ task: TaskItem) async -> Bool {
        var currentTasks = await fetchTasks()
        if let index = currentTasks.firstIndex(where: { $0.id == task.id }) {
            currentTasks[index] = task
            return await dataManager.saveTasks(currentTasks)
        }
        return false
    }
    
    func deleteTask(id: UUID) async -> Bool {
        var currentTasks = await fetchTasks()
        currentTasks.removeAll { $0.id == id }
        return await dataManager.saveTasks(currentTasks)
    }
    
    func toggleTaskCompletion(id: UUID) async -> Bool {
        var currentTasks = await fetchTasks()
        if let index = currentTasks.firstIndex(where: { $0.id == id }) {
            currentTasks[index].isCompleted.toggle()
            return await dataManager.saveTasks(currentTasks)
        }
        return false
    }
}

// MARK: - Supabase Task Repository Implementation
class SupabaseTaskRepository: TaskRepositoryProtocol {
    private let dataManager: DataManagerProtocol
    private let supabaseService: SupabaseServiceProtocol
    
    init(dataManager: DataManagerProtocol, supabaseService: SupabaseServiceProtocol) {
        self.dataManager = dataManager
        self.supabaseService = supabaseService
    }
    
    func fetchTasks() async -> [TaskItem] {
        do {
            let remoteTasks = try await supabaseService.getTasks()
            // Cache locally for offline access
            _ = await dataManager.saveTasks(remoteTasks)
            return remoteTasks
        } catch {
            print("Failed to fetch from Supabase, using local cache: \(error)")
            return await dataManager.loadTasks()
        }
    }
    
    func saveTask(_ task: TaskItem) async -> Bool {
        do {
            _ = try await supabaseService.createTask(task)
            
            // Update local cache
            var currentTasks = await dataManager.loadTasks()
            currentTasks.append(task)
            return await dataManager.saveTasks(currentTasks)
        } catch {
            print("Failed to save task to Supabase: \(error)")
            // Save locally for later sync
            var currentTasks = await dataManager.loadTasks()
            currentTasks.append(task)
            return await dataManager.saveTasks(currentTasks)
        }
    }
    
    func updateTask(_ task: TaskItem) async -> Bool {
        do {
            _ = try await supabaseService.updateTask(task)
            
            // Update local cache
            var currentTasks = await dataManager.loadTasks()
            if let index = currentTasks.firstIndex(where: { $0.id == task.id }) {
                currentTasks[index] = task
                return await dataManager.saveTasks(currentTasks)
            }
            return true
        } catch {
            print("Failed to update task in Supabase: \(error)")
            // Update locally for later sync
            var currentTasks = await dataManager.loadTasks()
            if let index = currentTasks.firstIndex(where: { $0.id == task.id }) {
                currentTasks[index] = task
                return await dataManager.saveTasks(currentTasks)
            }
            return false
        }
    }
    
    func deleteTask(id: UUID) async -> Bool {
        do {
            try await supabaseService.deleteTask(id: id)
            
            // Update local cache
            var currentTasks = await dataManager.loadTasks()
            currentTasks.removeAll { $0.id == id }
            return await dataManager.saveTasks(currentTasks)
        } catch {
            print("Failed to delete task from Supabase: \(error)")
            // Delete locally for later sync
            var currentTasks = await dataManager.loadTasks()
            currentTasks.removeAll { $0.id == id }
            return await dataManager.saveTasks(currentTasks)
        }
    }
    
    func toggleTaskCompletion(id: UUID) async -> Bool {
        var currentTasks = await dataManager.loadTasks()
        
        if let index = currentTasks.firstIndex(where: { $0.id == id }) {
            currentTasks[index].isCompleted.toggle()
            return await updateTask(currentTasks[index])
        }
        return false
    }
}

// MARK: - Repository Extensions for Multiple Tasks
extension TaskRepositoryProtocol {
    func saveTasks(_ tasks: [TaskItem]) async -> Bool {
        // This would be implemented in each repository type
        for task in tasks {
            let success = await saveTask(task)
            if !success { return false }
        }
        return true
    }
}
