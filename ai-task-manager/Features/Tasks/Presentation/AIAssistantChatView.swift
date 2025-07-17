//
//  AIAssistantChatView.swift
//  ai-task-manager
//
//  Conversational AI Assistant Interface for Task Management
//

import SwiftUI

struct AIAssistantChatView: View {
    @StateObject private var aiAssistant = AIAssistantService()
    @ObservedObject var taskViewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var messageText = ""
    @State private var isTyping = false
    @FocusState private var isMessageFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(aiAssistant.chatHistory) { message in
                                ChatMessageView(
                                    message: message,
                                    onTaskSuggestionAccepted: { suggestion in
                                        aiAssistant.createTaskFromSuggestion(suggestion, taskViewModel: taskViewModel)
                                    }
                                )
                                .id(message.id)
                            }
                            
                            // Typing indicator
                            if aiAssistant.isProcessing {
                                TypingIndicatorView()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: aiAssistant.chatHistory.count) { _, _ in
                        // Auto-scroll to bottom when new message arrives
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if let lastMessage = aiAssistant.chatHistory.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: aiAssistant.isProcessing) { _, isProcessing in
                        if isProcessing {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Message Input
                VStack(spacing: 8) {
                    // Quick Action Buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            QuickActionButton(
                                title: "Show Tasks",
                                icon: "list.bullet",
                                color: .blue
                            ) {
                                sendQuickMessage("Show my tasks")
                            }
                            
                            QuickActionButton(
                                title: "Add Task",
                                icon: "plus.circle",
                                color: .green
                            ) {
                                sendQuickMessage("I need to add a new task")
                            }
                            
                            QuickActionButton(
                                title: "What's Due Today?",
                                icon: "calendar.badge.clock",
                                color: .orange
                            ) {
                                sendQuickMessage("What do I have due today?")
                            }
                            
                            QuickActionButton(
                                title: "Help",
                                icon: "questionmark.circle",
                                color: .purple
                            ) {
                                sendQuickMessage("Help")
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Text Input
                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            TextField("Message your AI assistant...", text: $messageText, axis: .vertical)
                                .focused($isMessageFieldFocused)
                                .lineLimit(1...4)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .onSubmit {
                                    sendMessage()
                                }
                            
                            if !messageText.isEmpty {
                                Button(action: clearMessage) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .font(.title3)
                                }
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        
                        // Send Button
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(messageText.isEmpty ? .gray : .blue)
                        }
                        .disabled(messageText.isEmpty || aiAssistant.isProcessing)
                        .scaleEffect(messageText.isEmpty ? 0.8 : 1.0)
                        .animation(.spring(response: 0.3), value: messageText.isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear Chat") {
                        clearChat()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            // Small delay to ensure smooth animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isMessageFieldFocused = true
            }
        }
    }
    
    // MARK: - Actions
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = messageText
        messageText = ""
        
        Task {
            await aiAssistant.processUserMessage(message, taskViewModel: taskViewModel)
        }
    }
    
    private func sendQuickMessage(_ message: String) {
        messageText = message
        sendMessage()
    }
    
    private func clearMessage() {
        messageText = ""
    }
    
    private func clearChat() {
        aiAssistant.chatHistory.removeAll()
        aiAssistant.addWelcomeMessagePublic()
    }
}

// MARK: - Chat Message View
struct ChatMessageView: View {
    let message: ChatMessage
    let onTaskSuggestionAccepted: (TaskSuggestion) -> Void
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 50)
                UserMessageBubble(message: message)
            } else {
                AssistantMessageBubble(
                    message: message,
                    onTaskSuggestionAccepted: onTaskSuggestionAccepted
                )
                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - User Message Bubble
struct UserMessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(20, corners: [.topLeft, .topRight, .bottomLeft])
            
            Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Assistant Message Bubble
struct AssistantMessageBubble: View {
    let message: ChatMessage
    let onTaskSuggestionAccepted: (TaskSuggestion) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                // AI Avatar
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.purple)
                    .frame(width: 24, height: 24)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Message Content
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])
                    
                    // Task Suggestions
                    if let suggestions = message.suggestedTasks, !suggestions.isEmpty {
                        ForEach(suggestions) { suggestion in
                            TaskSuggestionCard(
                                suggestion: suggestion,
                                onAccept: {
                                    onTaskSuggestionAccepted(suggestion)
                                }
                            )
                        }
                    }
                }
            }
            
            Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.leading, 32)
        }
    }
}

// MARK: - Task Suggestion Card
struct TaskSuggestionCard: View {
    let suggestion: TaskSuggestion
    let onAccept: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Task Details
            VStack(alignment: .leading, spacing: 6) {
                Text(suggestion.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    Label(suggestion.category.rawValue, systemImage: suggestion.category.icon)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Label(suggestion.priority.rawValue, systemImage: "flag.fill")
                        .font(.caption)
                        .foregroundColor(Color.priorityColor(suggestion.priority))
                    
                    if let dueDate = suggestion.dueDate {
                        Label(dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Label(formatDuration(suggestion.estimatedDuration), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .foregroundColor(.secondary)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("✅ Add Task") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("✏️ Modify") {
                    // Could open edit view
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                // Confidence Indicator
                HStack(spacing: 4) {
                    Text("Confidence:")
                    Text("\(Int(suggestion.confidence * 100))%")
                        .fontWeight(.medium)
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
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

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(16)
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicatorView: View {
    @State private var animating = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 24, height: 24)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray5))
            .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])
            
            Spacer()
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

#Preview {
    AIAssistantChatView(taskViewModel: TaskViewModel())
}
