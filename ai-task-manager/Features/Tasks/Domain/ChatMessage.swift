//
//  ChatMessage.swift
//  ai-task-manager
//
//  Chat Message Models for AI Assistant
//

import Foundation

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Codable {
    var id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let messageType: MessageType
    var suggestedTasks: [TaskSuggestion]?
    var taskActions: [TaskAction]?
    
    init(content: String, isFromUser: Bool, messageType: MessageType = .text, suggestedTasks: [TaskSuggestion]? = nil, taskActions: [TaskAction]? = nil) {
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.messageType = messageType
        self.suggestedTasks = suggestedTasks
        self.taskActions = taskActions
    }
}

// MARK: - Message Type
enum MessageType: String, Codable {
    case text = "text"
    case taskSuggestion = "task_suggestion"
    case taskCreated = "task_created"
    case taskAction = "task_action"
    case greeting = "greeting"
    case help = "help"
}

// MARK: - Task Suggestion
struct TaskSuggestion: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let priority: TaskPriority
    let category: TaskCategory
    let dueDate: Date?
    let estimatedDuration: TimeInterval
    let keywords: [String]
    let confidence: Double // 0.0 to 1.0
    
    func toTaskItem() -> TaskItem {
        return TaskItem(
            title: title,
            description: description,
            priority: priority,
            category: category,
            dueDate: dueDate,
            estimatedDuration: estimatedDuration,
            keywords: keywords
        )
    }
}

// MARK: - Task Action
struct TaskAction: Identifiable, Codable {
    var id = UUID()
    let actionType: TaskActionType
    let taskId: UUID?
    let actionDescription: String
    
    enum TaskActionType: String, Codable {
        case create = "create"
        case complete = "complete"
        case delete = "delete"
        case update = "update"
        case reschedule = "reschedule"
        case setPriority = "set_priority"
    }
}
