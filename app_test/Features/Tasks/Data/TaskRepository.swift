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

// MARK: - Remote Task Repository (for future API integration)
class RemoteTaskRepository: TaskRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    private let localRepository: TaskRepositoryProtocol
    
    init(networkService: NetworkServiceProtocol, localRepository: TaskRepositoryProtocol) {
        self.networkService = networkService
        self.localRepository = localRepository
    }
    
    func fetchTasks() async -> [TaskItem] {
        // Try remote first, fallback to local
        do {
            let tasks = try await networkService.fetchTasks()
            // Cache locally
            _ = await localRepository.saveTasks(tasks)
            return tasks
        } catch {
            // Fallback to local cache
            return await localRepository.fetchTasks()
        }
    }
    
    func saveTask(_ task: TaskItem) async -> Bool {
        // Save locally first for offline support
        let localSuccess = await localRepository.saveTask(task)
        
        // Then sync to remote
        do {
            _ = try await networkService.createTask(task)
            return true
        } catch {
            return localSuccess
        }
    }
    
    func updateTask(_ task: TaskItem) async -> Bool {
        let localSuccess = await localRepository.updateTask(task)
        
        do {
            _ = try await networkService.updateTask(task)
            return true
        } catch {
            return localSuccess
        }
    }
    
    func deleteTask(id: UUID) async -> Bool {
        let localSuccess = await localRepository.deleteTask(id: id)
        
        do {
            _ = try await networkService.deleteTask(id: id)
            return true
        } catch {
            return localSuccess
        }
    }
    
    func toggleTaskCompletion(id: UUID) async -> Bool {
        return await localRepository.toggleTaskCompletion(id: id)
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
