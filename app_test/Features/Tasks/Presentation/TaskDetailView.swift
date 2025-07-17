//
//  TaskDetailView.swift
//  app_test
//
//  Detail View for Task Management
//

import SwiftUI

struct TaskDetailView: View {
    let task: TaskItem
    @ObservedObject var taskViewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var editTitle = ""
    @State private var editDescription = ""
    @State private var editPriority = TaskPriority.medium
    @State private var editCategory = TaskCategory.general
    @State private var editDueDate = Date()
    @State private var editHasDueDate = false
    @State private var editEstimatedDuration: TimeInterval = 1800
    @State private var editKeywords: [String] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Task Status Section
                    // Task Status Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Button {
                                taskViewModel.toggleTaskCompletion(task)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(task.isCompleted ? .green : .gray)
                                    Text(task.isCompleted ? "Completed" : "Mark Complete")
                                        .foregroundColor(task.isCompleted ? .green : .blue)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                        }
                    }
                    
                    // Task Details Section
                    if isEditing {
                        EditTaskSection(
                            title: $editTitle,
                            description: $editDescription,
                            priority: $editPriority,
                            category: $editCategory,
                            dueDate: $editDueDate,
                            hasDueDate: $editHasDueDate,
                            estimatedDuration: $editEstimatedDuration,
                            keywords: $editKeywords
                        )
                    } else {
                        // Task Info Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(task.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(task.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Label("Category", systemImage: task.category.icon)
                                Spacer()
                                Text(task.category.rawValue)
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Label("Priority", systemImage: "exclamationmark.triangle")
                                Spacer()
                                Text(task.priority.rawValue)
                                    .foregroundColor(Color.priorityColor(task.priority))
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Label("Duration", systemImage: "clock")
                                Spacer()
                                Text(formatDuration(task.estimatedDuration))
                                    .foregroundColor(.orange)
                                    .fontWeight(.medium)
                            }
                            
                            if !task.keywords.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Label("Keywords", systemImage: "tag")
                                        Spacer()
                                    }
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack {
                                            ForEach(task.keywords, id: \.self) { keyword in
                                                Text(keyword)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.purple.opacity(0.1))
                                                    .cornerRadius(8)
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            if let dueDate = task.dueDate {
                                HStack {
                                    Label("Due Date", systemImage: "calendar")
                                    Spacer()
                                    Text(dueDate.formatted())
                                        .foregroundColor(dueDate.isOverdue ? .red : .secondary)
                                }
                            }
                        }
                    }
                    
                    // Task Metadata
                    // Task Metadata Section
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Created", systemImage: "clock")
                        Text(task.createdAt.formatted())
                            .foregroundColor(.secondary)
                            .padding(.leading, 24)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Task Details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            saveChanges()
                        } else {
                            startEditing()
                        }
                    }
                }
                
                if isEditing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            cancelEditing()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func startEditing() {
        editTitle = task.title
        editDescription = task.description
        editPriority = task.priority
        editCategory = task.category
        editDueDate = task.dueDate ?? Date()
        editHasDueDate = task.dueDate != nil
        editEstimatedDuration = task.estimatedDuration
        editKeywords = task.keywords
        isEditing = true
    }
    
    private func saveChanges() {
        taskViewModel.updateTask(
            task,
            title: editTitle,
            description: editDescription,
            priority: editPriority,
            category: editCategory,
            dueDate: editHasDueDate ? editDueDate : nil,
            estimatedDuration: editEstimatedDuration,
            keywords: editKeywords
        )
        isEditing = false
    }
    
    private func cancelEditing() {
        isEditing = false
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

// MARK: - Task Status Section
struct TaskInfoRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: onToggle) {
                    HStack {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title)
                        Text(task.isCompleted ? "Completed" : "Mark as Complete")
                            .font(.headline)
                    }
                    .foregroundColor(task.isCompleted ? .green : .blue)
                }
                
                Spacer()
            }
            
            if task.isCompleted {
                Text("Task completed successfully!")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(task.isCompleted ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - View Task Section
struct TaskRowPreview: View {
    let task: TaskItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Title")
                .font(.headline)
                .foregroundColor(.secondary)
            Text(task.title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Description")
                .font(.headline)
                .foregroundColor(.secondary)
            Text(task.description)
                .font(.body)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Priority")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Circle()
                            .fill(Color.priorityColor(task.priority))
                            .frame(width: 12, height: 12)
                        Text(task.priority.rawValue)
                            .font(.body)
                    }
                }
                
                Spacer()
                
                if let dueDate = task.dueDate {
                    VStack(alignment: .trailing) {
                        Text("Due Date")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(dueDate.formatted())
                            .font(.body)
                            .foregroundColor(dueDate.isOverdue ? .red : .primary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Edit Task Section
struct EditTaskSection: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var priority: TaskPriority
    @Binding var category: TaskCategory
    @Binding var dueDate: Date
    @Binding var hasDueDate: Bool
    @Binding var estimatedDuration: TimeInterval
    @Binding var keywords: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading) {
                Text("Title")
                    .font(.headline)
                    .foregroundColor(.secondary)
                TextField("Task Title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading) {
                Text("Description")
                    .font(.headline)
                    .foregroundColor(.secondary)
                TextField("Description", text: $description, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
            
            VStack(alignment: .leading) {
                Text("Category")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Picker("Category", selection: $category) {
                    ForEach(TaskCategory.allCases, id: \.self) { category in
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.rawValue)
                        }
                        .tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            VStack(alignment: .leading) {
                Text("Priority")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Picker("Priority", selection: $priority) {
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        HStack {
                            Circle()
                                .fill(Color.priorityColor(priority))
                                .frame(width: 12, height: 12)
                            Text(priority.rawValue)
                        }
                        .tag(priority)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            VStack(alignment: .leading) {
                HStack {
                    Text("Estimated Duration:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDuration(estimatedDuration))
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
                
                Slider(value: $estimatedDuration, in: 300...14400, step: 300) // 5 min to 4 hours
            }
            
            VStack(alignment: .leading) {
                Toggle("Set Due Date", isOn: $hasDueDate)
                
                if hasDueDate {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                }
            }
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
}

// MARK: - Task Metadata Section
struct TaskMetadataRow: View {
    let task: TaskItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Task Information")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Label("Created", systemImage: "calendar.badge.plus")
                Spacer()
                Text(task.createdAt.formatted())
            }
            .font(.subheadline)
            
            HStack {
                Label("ID", systemImage: "number")
                Spacer()
                Text(task.id.uuidString.prefix(8).uppercased())
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    TaskDetailView(
        task: TaskItem(
            title: "Sample Task", 
            description: "This is a sample task for preview", 
            priority: .high,
            category: .work
        ),
        taskViewModel: TaskViewModel()
    )
}
