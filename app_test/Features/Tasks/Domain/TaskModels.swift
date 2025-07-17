import Foundation

// MARK: - Task Category Enum (moved here from NaturalLanguageService to avoid duplication)
enum TaskCategory: String, CaseIterable, Codable {
    case meeting = "Meeting"
    case shopping = "Shopping"
    case work = "Work"
    case personal = "Personal"
    case health = "Health"
    case finance = "Finance"
    case travel = "Travel"
    case general = "General"
    
    var icon: String {
        switch self {
        case .meeting: return "person.2.fill"
        case .shopping: return "cart.fill"
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .health: return "heart.fill"
        case .finance: return "dollarsign.circle.fill"
        case .travel: return "airplane"
        case .general: return "list.bullet"
        }
    }
}

// MARK: - Task Domain Models
struct TaskItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var priority: TaskPriority
    var category: TaskCategory
    var isCompleted: Bool
    var createdAt: Date
    var dueDate: Date?
    var estimatedDuration: TimeInterval
    var keywords: [String]
    
    init(title: String, description: String, priority: TaskPriority = .medium, category: TaskCategory = .general, dueDate: Date? = nil, estimatedDuration: TimeInterval = 1800, keywords: [String] = []) {
        self.title = title
        self.description = description
        self.priority = priority
        self.category = category
        self.isCompleted = false
        self.createdAt = Date()
        self.dueDate = dueDate
        self.estimatedDuration = estimatedDuration
        self.keywords = keywords
    }
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: String {
        switch self {
        case .low: return "blue"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

// MARK: - Task Use Cases / Business Logic
protocol TaskUseCaseProtocol {
    func getTasks() async -> [TaskItem]
    func createTask(_ task: TaskItem) async -> Bool
    func updateTask(_ task: TaskItem) async -> Bool
    func deleteTask(id: UUID) async -> Bool
    func completeTask(id: UUID) async -> Bool
}

class TaskUseCase: TaskUseCaseProtocol {
    private let repository: TaskRepositoryProtocol
    
    init(repository: TaskRepositoryProtocol) {
        self.repository = repository
    }
    
    func getTasks() async -> [TaskItem] {
        return await repository.fetchTasks()
    }
    
    func createTask(_ task: TaskItem) async -> Bool {
        return await repository.saveTask(task)
    }
    
    func updateTask(_ task: TaskItem) async -> Bool {
        return await repository.updateTask(task)
    }
    
    func deleteTask(id: UUID) async -> Bool {
        return await repository.deleteTask(id: id)
    }
    
    func completeTask(id: UUID) async -> Bool {
        return await repository.toggleTaskCompletion(id: id)
    }
}
