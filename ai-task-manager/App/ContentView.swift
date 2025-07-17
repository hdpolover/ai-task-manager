//
//  ContentView.swift
//  ai-task-manager
//
//  Main App Container with Tab Navigation
//  Demonstrates: Tab Views, Navigation, State Management
//

import SwiftUI

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.diContainer) private var diContainer
    
    var body: some View {
        TabView {
            TasksCoordinatorView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Tasks")
                }
                .badge(authManager.isAuthenticated ? nil : "Guest")
            
            AnalyticsCoordinatorView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Analytics")
                }
                .badge(authManager.isAuthenticated ? nil : "Guest")
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        .safeAreaInset(edge: .top) {
            if !authManager.isAuthenticated {
                GuestModeHeader()
            }
        }
    }
}

// MARK: - Feature Coordinators
struct TasksCoordinatorView: View {
    @Environment(\.diContainer) private var diContainer
    @StateObject private var viewModel: TaskViewModel
    
    init() {
        self._viewModel = StateObject(wrappedValue: DIContainer.shared.makeTaskViewModel())
    }
    
    var body: some View {
        TaskListView()
            .environmentObject(viewModel)
    }
}

struct AnalyticsCoordinatorView: View {
    @Environment(\.diContainer) private var diContainer
    @StateObject private var taskViewModel: TaskViewModel
    
    init() {
        self._taskViewModel = StateObject(wrappedValue: DIContainer.shared.makeTaskViewModel())
    }
    
    var body: some View {
        AnalyticsView()
            .environmentObject(taskViewModel)
    }
}

struct UsersCoordinatorView: View {
    @Environment(\.diContainer) private var diContainer
    @StateObject private var viewModel: UserViewModel
    
    init() {
        self._viewModel = StateObject(wrappedValue: DIContainer.shared.makeUserViewModel())
    }
    
    var body: some View {
        UserProfileView()
            .environmentObject(viewModel)
    }
}

// MARK: - Guest Mode Header
struct GuestModeHeader: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "person.circle")
                    .foregroundColor(.orange)
                Text("Guest Mode")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            Button("Sign In") {
                NotificationCenter.default.post(name: NSNotification.Name("ShowAuthentication"), object: nil)
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Color.orange.opacity(0.1)
                .overlay(
                    Rectangle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(height: 1),
                    alignment: .bottom
                )
        )
        .background(.regularMaterial, in: Rectangle())
    }
}

#Preview {
    ContentView()
        .withDependencies()
}

#Preview {
    ContentView()
        .withDependencies()
}
