//
//  AIAssistantService.swift
//  ai-task-manager
//
//  AI Assistant Service for Conversational Task Management
//

import Foundation

// MARK: - AI Assistant Service
class AIAssistantService: ObservableObject {
    private let nlService = NaturalLanguageService()
    @Published var chatHistory: [ChatMessage] = []
    @Published var isProcessing = false
    
    // AI personality and context
    private let assistantName = "TaskAI"
    private var conversationContext: [String] = []
    
    init() {
        // Start with a friendly greeting
        addWelcomeMessage()
    }
    
    // MARK: - Main Processing Function
    func processUserMessage(_ userInput: String, taskViewModel: TaskViewModel) async {
        // Add user message to chat
        let userMessage = ChatMessage(content: userInput, isFromUser: true)
        await MainActor.run {
            chatHistory.append(userMessage)
            isProcessing = true
        }
        
        // Add to conversation context
        conversationContext.append("User: \(userInput)")
        
        // Process the message and generate response
        let response = await generateAssistantResponse(userInput, taskViewModel: taskViewModel)
        
        await MainActor.run {
            chatHistory.append(response)
            isProcessing = false
        }
        
        conversationContext.append("Assistant: \(response.content)")
        
        // Keep context manageable (last 10 exchanges)
        if conversationContext.count > 20 {
            conversationContext = Array(conversationContext.suffix(20))
        }
    }
    
    // MARK: - Response Generation
    private func generateAssistantResponse(_ userInput: String, taskViewModel: TaskViewModel) async -> ChatMessage {
        let lowercaseInput = userInput.lowercased()
        
        // Determine intent
        let intent = determineIntent(lowercaseInput)
        
        switch intent {
        case .createTask:
            return await handleTaskCreation(userInput, taskViewModel: taskViewModel)
        case .listTasks:
            return await handleTaskListing(taskViewModel: taskViewModel)
        case .completeTask:
            return await handleTaskCompletion(userInput, taskViewModel: taskViewModel)
        case .deleteTask:
            return await handleTaskDeletion(userInput, taskViewModel: taskViewModel)
        case .updateTask:
            return await handleTaskUpdate(userInput, taskViewModel: taskViewModel)
        case .greeting:
            return generateGreetingResponse()
        case .help:
            return generateHelpResponse()
        case .general:
            return await handleGeneralQuery(userInput, taskViewModel: taskViewModel)
        }
    }
    
    // MARK: - Intent Recognition
    enum UserIntent {
        case createTask, listTasks, completeTask, deleteTask, updateTask, greeting, help, general
    }
    
    private func determineIntent(_ input: String) -> UserIntent {
        // Task creation patterns
        let createPatterns = ["add", "create", "new task", "need to", "have to", "should", "remember to", "don't forget"]
        if createPatterns.contains(where: input.contains) {
            return .createTask
        }
        
        // List tasks patterns
        let listPatterns = ["show", "list", "what tasks", "my tasks", "what do i have", "what's on my"]
        if listPatterns.contains(where: input.contains) {
            return .listTasks
        }
        
        // Complete task patterns
        let completePatterns = ["done", "finished", "completed", "mark complete", "finish"]
        if completePatterns.contains(where: input.contains) {
            return .completeTask
        }
        
        // Delete task patterns
        let deletePatterns = ["delete", "remove", "cancel", "get rid of"]
        if deletePatterns.contains(where: input.contains) {
            return .deleteTask
        }
        
        // Update task patterns
        let updatePatterns = ["change", "update", "modify", "edit", "reschedule"]
        if updatePatterns.contains(where: input.contains) {
            return .updateTask
        }
        
        // Greeting patterns
        let greetingPatterns = ["hello", "hi", "hey", "good morning", "good afternoon", "good evening"]
        if greetingPatterns.contains(where: input.contains) {
            return .greeting
        }
        
        // Help patterns
        let helpPatterns = ["help", "what can you do", "how do", "commands", "instructions"]
        if helpPatterns.contains(where: input.contains) {
            return .help
        }
        
        return .general
    }
    
    // MARK: - Task Creation Handler
    private func handleTaskCreation(_ input: String, taskViewModel: TaskViewModel) async -> ChatMessage {
        // Use NL service to analyze the task
        let nlResult = nlService.analyzeTaskText(input)
        
        // Extract task title from input
        let taskTitle = extractTaskTitle(from: input)
        let taskDescription = extractTaskDescription(from: input, title: taskTitle)
        
        // Create task suggestion
        let suggestion = TaskSuggestion(
            title: taskTitle,
            description: taskDescription,
            priority: nlResult.suggestedPriority,
            category: nlResult.suggestedCategory,
            dueDate: nlResult.extractedDueDate,
            estimatedDuration: nlResult.estimatedDuration,
            keywords: nlResult.extractedKeywords,
            confidence: calculateConfidence(nlResult)
        )
        
        // Generate personalized response
        let responseContent = generateTaskCreationResponse(suggestion: suggestion)
        
        return ChatMessage(
            content: responseContent,
            isFromUser: false,
            messageType: .taskSuggestion,
            suggestedTasks: [suggestion]
        )
    }
    
    // MARK: - Task Listing Handler
    @MainActor private func handleTaskListing(taskViewModel: TaskViewModel) -> ChatMessage {
        let pendingTasks = taskViewModel.pendingTasks
        
        if pendingTasks.isEmpty {
            return ChatMessage(
                content: "You're all caught up! 🎉 No pending tasks right now. Feel free to add something new whenever you're ready.",
                isFromUser: false,
                messageType: .text
            )
        }
        
        let taskCount = pendingTasks.count
        let highPriorityCount = pendingTasks.filter { $0.priority == .high }.count
        
        var response = "Here's what you have on your plate:\n\n"
        
        if highPriorityCount > 0 {
            response += "🔴 **High Priority (\(highPriorityCount)):**\n"
            for task in pendingTasks.filter({ $0.priority == .high }).prefix(3) {
                response += "• \(task.title)\n"
            }
            response += "\n"
        }
        
        let otherTasks = pendingTasks.filter { $0.priority != .high }
        if !otherTasks.isEmpty {
            response += "📋 **Other Tasks (\(otherTasks.count)):**\n"
            for task in otherTasks.prefix(5) {
                let dueDateText = task.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? ""
                response += "• \(task.title) \(dueDateText.isEmpty ? "" : "- \(dueDateText)")\n"
            }
        }
        
        if taskCount > 8 {
            response += "\n...and \(taskCount - 8) more tasks."
        }
        
        response += "\n\nWould you like me to help you prioritize or add something new?"
        
        return ChatMessage(content: response, isFromUser: false, messageType: .text)
    }
    
    // MARK: - Task Completion Handler
    private func handleTaskCompletion(_ input: String, taskViewModel: TaskViewModel) async -> ChatMessage {
        // Extract task reference from input
        let taskReference = extractTaskReference(from: input)
        let matchingTasks = await findMatchingTasks(reference: taskReference, in: taskViewModel.pendingTasks)
        
        if matchingTasks.isEmpty {
            return ChatMessage(
                content: "I couldn't find a task matching '\(taskReference)'. Could you be more specific? You can say something like 'mark call dentist as done' or just tell me the exact task title.",
                isFromUser: false,
                messageType: .text
            )
        }
        
        if matchingTasks.count == 1 {
            let task = matchingTasks[0]
            await MainActor.run {
                taskViewModel.toggleTaskCompletion(task)
            }
            
            let responses = [
                "✅ Great job! '\(task.title)' is now complete. That must feel good!",
                "🎉 Awesome! You've finished '\(task.title)'. One less thing to worry about!",
                "✨ Nice work! '\(task.title)' is done and dusted. What's next?",
                "🙌 Excellent! '\(task.title)' is completed. You're making great progress!"
            ]
            
            return ChatMessage(
                content: responses.randomElement() ?? responses[0],
                isFromUser: false,
                messageType: .taskCreated
            )
        } else {
            var response = "I found multiple tasks that might match. Which one did you complete?\n\n"
            for (index, task) in matchingTasks.enumerated() {
                response += "\(index + 1). \(task.title)\n"
            }
            response += "\nJust tell me the number or the full title."
            
            return ChatMessage(content: response, isFromUser: false, messageType: .text)
        }
    }
    
    // MARK: - Helper Functions
    private func extractTaskTitle(from input: String) -> String {
        // Remove common prefixes
        var cleaned = input
        let prefixes = ["add", "create", "new task", "i need to", "i have to", "i should", "remember to", "don't forget to", "remind me to"]
        
        for prefix in prefixes {
            if cleaned.lowercased().hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        // Capitalize first letter
        return cleaned.prefix(1).capitalized + cleaned.dropFirst()
    }
    
    private func extractTaskDescription(from input: String, title: String) -> String {
        if input.count > title.count + 20 {
            return "Created from: \(input)"
        }
        return "Task created via AI assistant"
    }
    
    private func calculateConfidence(_ nlResult: NLProcessingResult) -> Double {
        var confidence = 0.7 // Base confidence
        
        if nlResult.extractedDueDate != nil { confidence += 0.1 }
        if nlResult.suggestedCategory != .general { confidence += 0.1 }
        if !nlResult.extractedKeywords.isEmpty { confidence += 0.1 }
        
        return min(confidence, 1.0)
    }
    
    private func generateTaskCreationResponse(suggestion: TaskSuggestion) -> String {
        var response = "I'll help you create that task! Here's what I understood:\n\n"
        response += "📝 **Task:** \(suggestion.title)\n"
        response += "📂 **Category:** \(suggestion.category.rawValue)\n"
        response += "🚩 **Priority:** \(suggestion.priority.rawValue)\n"
        
        if let dueDate = suggestion.dueDate {
            response += "📅 **Due:** \(dueDate.formatted(date: .abbreviated, time: .shortened))\n"
        }
        
        response += "⏱️ **Estimated Time:** \(formatDuration(suggestion.estimatedDuration))\n\n"
        
        let confirmationPhrases = [
            "Does this look right? I can create it for you!",
            "Sound good? I'll add it to your list!",
            "Ready to add this to your tasks?",
            "Should I go ahead and create this task?"
        ]
        
        response += confirmationPhrases.randomElement() ?? confirmationPhrases[0]
        
        return response
    }
    
    private func extractTaskReference(from input: String) -> String {
        // Remove completion keywords and extract the task reference
        var cleaned = input.lowercased()
        let patterns = ["mark", "complete", "done", "finished", "finish", "as done", "as complete"]
        
        for pattern in patterns {
            cleaned = cleaned.replacingOccurrences(of: pattern, with: "")
        }
        
        return cleaned.trimmingCharacters(in: .whitespaces)
    }
    
    private func findMatchingTasks(reference: String, in tasks: [TaskItem]) -> [TaskItem] {
        return tasks.filter { task in
            task.title.lowercased().contains(reference) ||
            task.description.lowercased().contains(reference) ||
            task.keywords.contains { $0.lowercased().contains(reference) }
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
    
    // MARK: - Additional Handlers
    private func handleTaskDeletion(_ input: String, taskViewModel: TaskViewModel) async -> ChatMessage {
        return ChatMessage(
            content: "I can help you remove tasks! Which task would you like to delete? Just tell me the task name.",
            isFromUser: false,
            messageType: .text
        )
    }
    
    private func handleTaskUpdate(_ input: String, taskViewModel: TaskViewModel) async -> ChatMessage {
        return ChatMessage(
            content: "I can help you update tasks! What would you like to change? You can reschedule, change priority, or modify the description.",
            isFromUser: false,
            messageType: .text
        )
    }
    
    private func handleGeneralQuery(_ input: String, taskViewModel: TaskViewModel) async -> ChatMessage {
        let responses = [
            "I'm here to help you manage your tasks! Try telling me something like 'add call dentist tomorrow' or 'show my tasks'.",
            "I can help you create tasks, check your list, or mark things as complete. What would you like to do?",
            "Not sure what you need? Try saying 'help' to see what I can do, or just tell me about a task you want to add!",
            "I'm your personal task assistant! I can understand natural language - just tell me what you need to get done."
        ]
        
        return ChatMessage(
            content: responses.randomElement() ?? responses[0],
            isFromUser: false,
            messageType: .text
        )
    }
    
    private func generateGreetingResponse() -> ChatMessage {
        let greetings = [
            "Hey there! 👋 I'm your AI task assistant. What can I help you organize today?",
            "Hello! ✨ Ready to tackle your to-do list? Just tell me what you need to get done!",
            "Hi! 🚀 I'm here to help you stay organized. What's on your mind?",
            "Welcome back! 😊 Let's make today productive. What tasks can I help you with?"
        ]
        
        return ChatMessage(
            content: greetings.randomElement() ?? greetings[0],
            isFromUser: false,
            messageType: .greeting
        )
    }
    
    private func generateHelpResponse() -> ChatMessage {
        let helpContent = """
        I'm your AI task assistant! Here's what I can do:
        
        **📝 Creating Tasks:**
        • "Add call dentist tomorrow"
        • "Remember to buy groceries"
        • "I need to finish the project by Friday"
        
        **📋 Managing Tasks:**
        • "Show my tasks"
        • "What do I have today?"
        • "Mark call dentist as done"
        
        **🎯 Smart Features:**
        • I understand dates like "tomorrow", "next week"
        • I detect priority from words like "urgent"
        • I categorize tasks automatically
        • I estimate how long tasks will take
        
        Just talk to me naturally - I'll understand! 😊
        """
        
        return ChatMessage(
            content: helpContent,
            isFromUser: false,
            messageType: .help
        )
    }
    
    // MARK: - Welcome Message
    private func addWelcomeMessage() {
        let welcomeMessage = ChatMessage(
            content: "Hi! I'm your AI task assistant 🤖✨\n\nI'm here to help you organize your life naturally. Just tell me what you need to do, and I'll take care of the details!\n\nTry saying something like:\n• \"Add call dentist tomorrow\"\n• \"Show my tasks\"\n• \"I need to buy groceries tonight\"",
            isFromUser: false,
            messageType: .greeting
        )
        chatHistory.append(welcomeMessage)
    }
    
    // MARK: - Public Methods for Chat Management
    func addWelcomeMessagePublic() {
        addWelcomeMessage()
    }
    
    // MARK: - Task Actions
    @MainActor func createTaskFromSuggestion(_ suggestion: TaskSuggestion, taskViewModel: TaskViewModel) {
        let task = suggestion.toTaskItem()
        taskViewModel.addTask(
            title: task.title,
            description: task.description,
            priority: task.priority,
            category: task.category,
            dueDate: task.dueDate,
            estimatedDuration: task.estimatedDuration,
            keywords: task.keywords
        )
        
        let confirmationMessage = ChatMessage(
            content: "✅ Perfect! I've added '\(task.title)' to your tasks. It's all set up with the details we discussed!",
            isFromUser: false,
            messageType: .taskCreated
        )
        chatHistory.append(confirmationMessage)
    }
}
