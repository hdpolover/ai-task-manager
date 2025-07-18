//
//  TaskListView.swift
//  ai-task-manager
//
//  Clean Architecture - View Layer (SwiftUI Views)
//

import SwiftUI

struct TaskListView: View {
    @StateObject private var taskViewModel = TaskViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingAddTask = false
    @State private var showingAIAssistant = false
    @State private var showingTaskDetail: TaskItem?
    
    var body: some View {
        NavigationView {
            ZStack {
                mainContentView
                floatingButtonView
            }
            .navigationTitle("Tasks")
            .toolbar {
                toolbarItems
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(taskViewModel: taskViewModel)
        }
        .fullScreenCover(isPresented: $showingAIAssistant) {
            AIAssistantChatView(taskViewModel: taskViewModel)
        }
        .sheet(item: $showingTaskDetail) { task in
            TaskDetailView(task: task, taskViewModel: taskViewModel)
        }
        .alert("Error", isPresented: $taskViewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(taskViewModel.errorMessage ?? "Unknown error occurred")
        }
        .alert(taskViewModel.authPromptTitle, isPresented: $taskViewModel.showingAuthPrompt) {
            Button("Sign In") {
                NotificationCenter.default.post(name: NSNotification.Name("ShowAuthentication"), object: nil)
            }
            Button("Continue as Guest", role: .cancel) { }
        } message: {
            Text(taskViewModel.authPromptMessage)
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        VStack {
            // Stats Header
            TaskStatsView(viewModel: taskViewModel)
            
            // Task List
            taskListView
        }
        .background(themeManager.isDarkMode ? Color.black : Color(.systemGroupedBackground))
    }
    
    @ViewBuilder
    private var taskListView: some View {
        if taskViewModel.isLoading {
            Spacer()
            ProgressView("Loading tasks...")
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            Spacer()
        } else if taskViewModel.tasks.isEmpty {
            EmptyStateView(
                title: "No Tasks Yet",
                message: "Try the AI Assistant to create your first task naturally!",
                systemImage: "brain.head.profile"
            )
        } else {
            taskList
        }
    }
    
    @ViewBuilder
    private var taskList: some View {
        List {
            ForEach(taskViewModel.tasks) { task in
                TaskRowView(task: task) {
                    taskViewModel.toggleTaskCompletion(task)
                }
                .onTapGesture {
                    showingTaskDetail = task
                }
                .listRowBackground(
                    themeManager.isDarkMode ? 
                    Color(.systemGray6) : Color(.systemBackground)
                )
            }
            .onDelete(perform: taskViewModel.deleteTask)
        }
        .refreshable {
            taskViewModel.syncWithRemote()
        }
        .background(themeManager.isDarkMode ? Color.black : Color.white)
    }
    
    @ViewBuilder
    private var floatingButtonView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                AIFloatingActionButton {
                    if taskViewModel.isGuestMode {
                        taskViewModel.promptForAIAssistant()
                    } else {
                        showingAIAssistant = true
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                if taskViewModel.isGuestMode {
                    taskViewModel.promptForAIAssistant()
                } else {
                    showingAIAssistant = true
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: taskViewModel.isGuestMode ? "lock.fill" : "brain.head.profile")
                    Text("AI Assistant")
                    if taskViewModel.isGuestMode {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
            .foregroundColor(taskViewModel.isGuestMode ? .orange : (themeManager.isDarkMode ? .white : .purple))
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                Button(taskViewModel.isGuestMode ? "Sync" : "Refresh") {
                    taskViewModel.syncWithRemote()
                }
                .foregroundColor(taskViewModel.isGuestMode ? .orange : (themeManager.isDarkMode ? .white : .blue))
                
                Button("Add Task") {
                    if taskViewModel.canAddMoreTasks {
                        showingAddTask = true
                    } else {
                        taskViewModel.promptForAIAssistant()
                    }
                }
                .foregroundColor(taskViewModel.canAddMoreTasks ? (themeManager.isDarkMode ? .white : .green) : .orange)
            }
        }
    }
}

// MARK: - Task Stats View
struct TaskStatsView: View {
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Guest Mode or AI Tip
            HStack {
                Image(systemName: viewModel.isGuestMode ? "person.circle" : "lightbulb.fill")
                    .foregroundColor(viewModel.isGuestMode ? .orange : .yellow)
                
                if viewModel.isGuestMode {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Guest Mode - \(viewModel.guestTasksRemaining) tasks remaining")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                        Text("Sign in for unlimited tasks and AI features")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Try: \"Add call dentist tomorrow\" or \"Show my urgent tasks\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            // Stats Cards
            HStack(spacing: 12) {
                TaskStatCard(title: "Total", count: viewModel.tasks.count, color: .blue)
                TaskStatCard(title: "Pending", count: viewModel.pendingTasks.count, color: .orange)
                TaskStatCard(title: "Done", count: viewModel.completedTasks.count, color: .green)
                
                // AI-Enhanced stat or Guest limit
                VStack {
                    HStack {
                        Image(systemName: viewModel.isGuestMode ? "person.circle" : "brain")
                            .font(.caption)
                            .foregroundColor(viewModel.isGuestMode ? .orange : .purple)
                        Text("\(viewModel.isGuestMode ? viewModel.guestTasksRemaining : aiCreatedTasksCount(viewModel.tasks))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(viewModel.isGuestMode ? .orange : .purple)
                    }
                    Text(viewModel.isGuestMode ? "Remaining" : "AI Created")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background((viewModel.isGuestMode ? Color.orange : Color.purple).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke((viewModel.isGuestMode ? Color.orange : Color.purple).opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private func aiCreatedTasksCount(_ tasks: [TaskItem]) -> Int {
        // Count tasks with AI-generated descriptions or keywords
        return tasks.filter { task in
            task.description.contains("AI assistant") || 
            task.description.contains("Created from:") ||
            !task.keywords.isEmpty
        }.count
    }
}

// MARK: - Task Stat Card
struct TaskStatCard: View {
    let title: String
    let count: Int
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.isDarkMode ? .white : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(
            color.opacity(themeManager.isDarkMode ? 0.3 : 0.1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(themeManager.isDarkMode ? 0.6 : 0.3), lineWidth: 1)
        )
        .cornerRadius(8)
        .shadow(
            color: themeManager.isDarkMode ? .clear : .gray.opacity(0.2),
            radius: themeManager.isDarkMode ? 0 : 2,
            x: 0,
            y: 1
        )
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    let task: TaskItem
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                Text(task.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    // Category
                    Label(task.category.rawValue, systemImage: task.category.icon)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    // Priority
                    Label(task.priority.rawValue, systemImage: "flag.fill")
                        .font(.caption)
                        .foregroundColor(Color.priorityColor(task.priority))
                    
                    Spacer()
                    
                    // Duration
                    if task.estimatedDuration > 0 {
                        Label(formatDuration(task.estimatedDuration), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    // Due Date
                    if let dueDate = task.dueDate {
                        Label(dueDate.formatted(), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(dueDate.isOverdue ? .red : .secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
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

#Preview {
    TaskListView()
}
