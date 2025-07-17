import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.diContainer) private var diContainer
    @State private var showingResetAlert = false
    @State private var showingOnboardingResetAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Theme Section
                Section("Appearance") {
                    HStack {
                        Label("Dark Mode", systemImage: "moon.fill")
                        Spacer()
                        Toggle("", isOn: $themeManager.isDarkMode)
                    }
                }
                
                // Data Section
                Section("Data Management") {
                    Button(action: { showingOnboardingResetAlert = true }) {
                        Label("Show Onboarding Again", systemImage: "arrow.clockwise")
                            .foregroundColor(.theme.accent)
                    }
                    
                    Button(action: { showingResetAlert = true }) {
                        Label("Reset All Data", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Architecture", systemImage: "building.2")
                        Spacer()
                        Text("Clean MVVM")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Framework", systemImage: "swift")
                        Spacer()
                        Text("SwiftUI")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Developer Section
                Section("Developer") {
                    NavigationLink(destination: DebugView()) {
                        Label("Debug Information", systemImage: "ladybug")
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will permanently delete all tasks and users. This action cannot be undone.")
        }
        .alert("Show Onboarding", isPresented: $showingOnboardingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Show Onboarding", role: .destructive) {
                resetOnboarding()
            }
        } message: {
            Text("This will reset the onboarding flow and show it again when you restart the app.")
        }
    }
    
    private func resetAllData() {
        _Concurrency.Task {
            let dataManager = diContainer.getDataManager()
            await dataManager.saveTasks([])
            await dataManager.saveUsers([])
        }
    }
    
    private func resetOnboarding() {
        let onboardingRepository = diContainer.getOnboardingRepository()
        onboardingRepository.resetOnboarding()
    }
}

// MARK: - Debug View
struct DebugView: View {
    @Environment(\.diContainer) private var diContainer
    @State private var tasks: [TaskItem] = []
    @State private var users: [User] = []
    
    var body: some View {
        List {
            Section("Tasks Debug Info") {
                Text("Total Tasks: \(tasks.count)")
                Text("Completed: \(tasks.filter { $0.isCompleted }.count)")
                Text("High Priority: \(tasks.filter { $0.priority == .high }.count)")
            }
            
            Section("Users Debug Info") {
                Text("Total Users: \(users.count)")
                Text("Active Users: \(users.filter { $0.isActive }.count)")
                Text("Admin Users: \(users.filter { $0.role == .admin }.count)")
            }
            
            Section("System Info") {
                Text("iOS Version: \(UIDevice.current.systemVersion)")
                Text("Device Model: \(UIDevice.current.model)")
                Text("App Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
            }
        }
        .navigationTitle("Debug Info")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await loadDebugData()
        }
    }
    
    private func loadDebugData() async {
        let dataManager = diContainer.getDataManager()
        tasks = await dataManager.loadTasks()
        users = await dataManager.loadUsers()
    }
}

#Preview {
    SettingsView()
        .withDependencies()
}
