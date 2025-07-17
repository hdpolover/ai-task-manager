//
//  AnalyticsView.swift
//  ai-task-manager
//
//  Analytics and insights view to replace Users tab
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject private var taskViewModel: TaskViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedTimeRange: TimeRange = .week
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Picker
                    timeRangePicker
                    
                    // Task Statistics Cards
                    statisticsCards
                    
                    // Task Completion Chart
                    completionChart
                    
                    // Category Distribution
                    categoryChart
                    
                    // Priority Distribution
                    priorityChart
                    
                    // Recent Activity
                    recentActivity
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                taskViewModel.loadTasks()
            }
        }
    }
    
    // MARK: - Time Range Picker
    private var timeRangePicker: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.displayName).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    // MARK: - Statistics Cards
    private var statisticsCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Total Tasks",
                value: "\(taskViewModel.tasks.count)",
                icon: "list.bullet",
                color: .blue
            )
            
            StatCard(
                title: "Completed",
                value: "\(completedTasksCount)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "In Progress",
                value: "\(inProgressTasksCount)",
                icon: "clock.fill",
                color: .orange
            )
            
            StatCard(
                title: "Completion Rate",
                value: "\(completionRate)%",
                icon: "chart.line.uptrend.xyaxis",
                color: .purple
            )
        }
    }
    
    // MARK: - Completion Chart
    private var completionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task Completion Trend")
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart(completionData) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Completed", data.completed)
                    )
                    .foregroundStyle(.green)
                    
                    AreaMark(
                        x: .value("Date", data.date),
                        y: .value("Completed", data.completed)
                    )
                    .foregroundStyle(.green.opacity(0.3))
                }
                .frame(height: 200)
            } else {
                // Fallback for iOS 15
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        Text("Chart requires iOS 16+")
                            .foregroundColor(.secondary)
                    )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Category Chart
    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tasks by Category")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(categoryData, id: \.category) { data in
                    CategoryCard(
                        category: data.category,
                        count: data.count,
                        percentage: data.percentage
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Priority Chart
    private var priorityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tasks by Priority")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach(priorityData, id: \.priority) { data in
                    PriorityRow(
                        priority: data.priority,
                        count: data.count,
                        percentage: data.percentage
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Recent Activity
    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach(recentTasks.prefix(5), id: \.id) { task in
                    ActivityRow(task: task)
                }
                
                if recentTasks.isEmpty {
                    Text("No recent activity")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    private var completedTasksCount: Int {
        taskViewModel.tasks.filter { $0.isCompleted }.count
    }
    
    private var inProgressTasksCount: Int {
        taskViewModel.tasks.filter { !$0.isCompleted }.count
    }
    
    private var completionRate: Int {
        guard !taskViewModel.tasks.isEmpty else { return 0 }
        return Int((Double(completedTasksCount) / Double(taskViewModel.tasks.count)) * 100)
    }
    
    private var completionData: [CompletionData] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        var data: [CompletionData] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let tasksCompleted = taskViewModel.tasks.filter { task in
                calendar.isDate(task.createdAt, inSameDayAs: currentDate) && task.isCompleted
            }.count
            
            data.append(CompletionData(date: currentDate, completed: tasksCompleted))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return data
    }
    
    private var categoryData: [CategoryData] {
        let totalTasks = taskViewModel.tasks.count
        guard totalTasks > 0 else { return [] }
        
        return TaskCategory.allCases.compactMap { category in
            let count = taskViewModel.tasks.filter { $0.category == category }.count
            guard count > 0 else { return nil }
            let percentage = Int((Double(count) / Double(totalTasks)) * 100)
            return CategoryData(category: category, count: count, percentage: percentage)
        }
    }
    
    private var priorityData: [PriorityData] {
        let totalTasks = taskViewModel.tasks.count
        guard totalTasks > 0 else { return [] }
        
        return TaskPriority.allCases.map { priority in
            let count = taskViewModel.tasks.filter { $0.priority == priority }.count
            let percentage = Int((Double(count) / Double(totalTasks)) * 100)
            return PriorityData(priority: priority, count: count, percentage: percentage)
        }
    }
    
    private var recentTasks: [TaskItem] {
        taskViewModel.tasks
            .sorted { $0.createdAt > $1.createdAt }
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CategoryCard: View {
    let category: TaskCategory
    let count: Int
    let percentage: Int
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(count) tasks (\(percentage)%)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct PriorityRow: View {
    let priority: TaskPriority
    let count: Int
    let percentage: Int
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(priority.color))
                .frame(width: 12, height: 12)
            
            Text(priority.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text("\(count) tasks")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("(\(percentage)%)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct ActivityRow: View {
    let task: TaskItem
    
    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                
                Text(task.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: task.category.icon)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

// MARK: - Data Models
struct CompletionData: Identifiable {
    let id = UUID()
    let date: Date
    let completed: Int
}

struct CategoryData {
    let category: TaskCategory
    let count: Int
    let percentage: Int
}

struct PriorityData {
    let priority: TaskPriority
    let count: Int
    let percentage: Int
}

enum TimeRange: CaseIterable {
    case week, month, quarter, year
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        }
    }
}

#Preview {
    AnalyticsView()
        .withDependencies()
}
