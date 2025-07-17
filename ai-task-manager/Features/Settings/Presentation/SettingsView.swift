import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.diContainer) private var diContainer
    @StateObject private var userProfileViewModel: UserProfileViewModel
    @State private var showingResetAlert = false
    @State private var showingOnboardingResetAlert = false
    @State private var showingUserProfileSheet = false
    @State private var showingSignOutAlert = false
    
    init() {
        self._userProfileViewModel = StateObject(wrappedValue: UserProfileViewModel())
    }
    
    var body: some View {
        NavigationView {
            List {
                // Authentication Section
                Section("Account") {
                    if authManager.isAuthenticated {
                        accountSection
                    } else {
                        notSignedInSection
                    }
                }
                
                // User Profile Section
                if authManager.isAuthenticated {
                    Section("Profile") {
                        if userProfileViewModel.hasProfile {
                            userProfileSection
                        } else {
                            createProfileSection
                        }
                    }
                }
                
                // Theme Section
                Section("Appearance") {
                    HStack {
                        Label("Dark Mode", systemImage: "moon.fill")
                        Spacer()
                        Toggle("", isOn: $themeManager.isDarkMode)
                    }
                }
                
                // Preferences Section
                if userProfileViewModel.hasProfile {
                    preferencesSection
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
                        Text("Clean MVVM + Supabase")
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
        .sheet(isPresented: $showingUserProfileSheet) {
            UserProfileEditView(viewModel: userProfileViewModel)
        }
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will permanently delete all tasks and profile data. This action cannot be undone.")
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
    
    // MARK: - Authentication Sections
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(authManager.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let email = authManager.currentUser?.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button("Sign Out") {
                    showingSignOutAlert = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.red)
            }
            
            Text("Signed in")
                .font(.caption)
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    private var notSignedInSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Guest Mode")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Sign in to unlock all features")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "person.circle")
                    .font(.title2)
                    .foregroundColor(.orange)
            }
            
            Text("Using local storage only")
                .font(.caption)
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                FeatureItem(icon: "cloud.fill", title: "Cloud Sync", description: "Sync tasks across devices")
                FeatureItem(icon: "brain.head.profile", title: "AI Assistant", description: "Natural language task creation")
                FeatureItem(icon: "chart.bar.fill", title: "Analytics", description: "Detailed insights and trends")
                FeatureItem(icon: "person.2.fill", title: "Collaboration", description: "Share tasks with others")
            }
            .padding(.top, 8)
            
            Button("Sign In to Unlock Features") {
                NotificationCenter.default.post(name: NSNotification.Name("ShowAuthentication"), object: nil)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - User Profile Section
    private var userProfileSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(userProfileViewModel.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(userProfileViewModel.displayEmail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Edit") {
                    showingUserProfileSheet = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            if let profile = userProfileViewModel.profile {
                Text("Member since \(profile.createdAt, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var createProfileSection: some View {
        Button(action: {
            showingUserProfileSheet = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Profile")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Set up your profile to sync across devices")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        Section("Preferences") {
            if let preferences = userProfileViewModel.profile?.preferences {
                VStack(spacing: 12) {
                    HStack {
                        Label("Notifications", systemImage: "bell")
                        Spacer()
                        Toggle("", isOn: .constant(preferences.notificationsEnabled))
                            .onChange(of: preferences.notificationsEnabled) { value in
                                var newPreferences = preferences
                                newPreferences.notificationsEnabled = value
                                userProfileViewModel.updatePreferences(newPreferences)
                            }
                    }
                    
                    HStack {
                        Label("Default Category", systemImage: "folder")
                        Spacer()
                        Text(preferences.defaultTaskCategory.rawValue)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Default Priority", systemImage: "flag")
                        Spacer()
                        Text(preferences.defaultTaskPriority.rawValue)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func resetAllData() {
        _Concurrency.Task {
            let dataManager = diContainer.getDataManager()
            await dataManager.saveTasks([])
            _ = await dataManager.saveUserProfile(UserProfile(name: "", email: ""))
        }
    }
    
    private func resetOnboarding() {
        let onboardingRepository = diContainer.getOnboardingRepository()
        onboardingRepository.resetOnboarding()
    }
    
    private func signOut() {
        _Concurrency.Task {
            await authManager.signOut()
        }
    }
}

// MARK: - User Profile Edit View
struct UserProfileEditView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("Name", text: $viewModel.editName)
                        .autocorrectionDisabled()
                    
                    TextField("Email", text: $viewModel.editEmail)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                }
                
                Section("Preferences") {
                    Toggle("Enable Notifications", isOn: $viewModel.editPreferences.notificationsEnabled)
                    
                    Picker("Default Category", selection: $viewModel.editPreferences.defaultTaskCategory) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    
                    Picker("Default Priority", selection: $viewModel.editPreferences.defaultTaskPriority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(viewModel.hasProfile ? "Edit Profile" : "Create Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.cancelEditing()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(viewModel.hasProfile ? "Save" : "Create") {
                        if viewModel.hasProfile {
                            viewModel.updateProfile()
                        } else {
                            viewModel.createProfile(
                                name: viewModel.editName,
                                email: viewModel.editEmail
                            )
                        }
                        
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
        }
    }
}

// MARK: - Debug View
struct DebugView: View {
    @Environment(\.diContainer) private var diContainer
    @State private var tasks: [TaskItem] = []
    @State private var userProfile: UserProfile?
    @State private var isConnectedToSupabase = false
    
    var body: some View {
        List {
            Section("Tasks Debug Info") {
                Text("Total Tasks: \(tasks.count)")
                Text("Completed: \(tasks.filter { $0.isCompleted }.count)")
                Text("High Priority: \(tasks.filter { $0.priority == .high }.count)")
                
                if !tasks.isEmpty {
                    Text("Most Recent: \(tasks.sorted { $0.createdAt > $1.createdAt }.first?.title ?? "None")")
                }
            }
            
            Section("User Profile Debug Info") {
                if let profile = userProfile {
                    Text("Name: \(profile.name)")
                    Text("Email: \(profile.email)")
                    Text("Notifications: \(profile.preferences.notificationsEnabled ? "Enabled" : "Disabled")")
                    Text("Default Category: \(profile.preferences.defaultTaskCategory.rawValue)")
                } else {
                    Text("No user profile found")
                }
            }
            
            Section("Supabase Integration") {
                HStack {
                    Text("Service Type:")
                    Spacer()
                    Text(isConnectedToSupabase ? "Real Supabase" : "Mock Service")
                        .foregroundColor(isConnectedToSupabase ? .green : .orange)
                }
                
                Text("Database: PostgreSQL with RLS")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Test Connection") {
                    testSupabaseConnection()
                }
                .buttonStyle(.bordered)
            }
            
            Section("System Info") {
                Text("iOS Version: \(UIDevice.current.systemVersion)")
                Text("Device Model: \(UIDevice.current.model)")
                Text("App Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
                Text("Architecture: Clean MVVM + Supabase")
            }
            
            Section("Data Management") {
                Button("Sync with Supabase") {
                    syncData()
                }
                .buttonStyle(.bordered)
                
                Button("Clear Local Cache") {
                    clearLocalCache()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
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
        userProfile = await dataManager.loadUserProfile()
        
        // Check if using real Supabase service
        let supabaseService = diContainer.getSupabaseService()
        isConnectedToSupabase = !(supabaseService is MockSupabaseService)
    }
    
    private func testSupabaseConnection() {
        _Concurrency.Task {
            do {
                let supabaseService = diContainer.getSupabaseService()
                _ = try await supabaseService.getTasks()
                print("✅ Supabase connection successful")
            } catch {
                print("❌ Supabase connection failed: \(error)")
            }
        }
    }
    
    private func syncData() {
        _Concurrency.Task {
            let dataManager = diContainer.getDataManager()
            let success = await dataManager.syncTasksWithRemote()
            print(success ? "✅ Sync successful" : "❌ Sync failed")
            await loadDebugData()
        }
    }
    
    private func clearLocalCache() {
        _Concurrency.Task {
            let dataManager = diContainer.getDataManager()
            await dataManager.saveTasks([])
            await loadDebugData()
        }
    }
}

// MARK: - Feature Item Component
struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.caption2)
                .foregroundColor(.orange)
        }
    }
}

#Preview {
    SettingsView()
        .withDependencies()
}
