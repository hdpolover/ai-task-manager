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
    @Environment(\.diContainer) private var diContainer
    
    var body: some View {
        TabView {
            TasksCoordinatorView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Tasks")
                }
            
            UsersCoordinatorView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Users")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
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

#Preview {
    ContentView()
        .withDependencies()
}

#Preview {
    ContentView()
        .withDependencies()
}
