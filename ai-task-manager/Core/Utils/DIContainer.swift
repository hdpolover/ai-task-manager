import Foundation
import SwiftUI

// MARK: - Dependency Injection Container
class DIContainer: ObservableObject {
    
    // MARK: - Shared Instance
    static let shared = DIContainer()
    
    // MARK: - Core Services
    private lazy var supabaseService: SupabaseServiceProtocol = SupabaseService()
    private lazy var dataManager: DataManagerProtocol = DataManager(supabaseService: supabaseService)
    private lazy var themeManager: ThemeManager = ThemeManager.shared
    private var _authManager: AuthenticationManager?
    
    // MARK: - Repositories
    private lazy var taskRepository: TaskRepositoryProtocol = SupabaseTaskRepository(dataManager: dataManager, supabaseService: supabaseService)
    private lazy var userRepository: UserRepositoryProtocol = LocalUserRepository(dataManager: dataManager)
    private lazy var userProfileRepository: UserProfileRepositoryProtocol = UserProfileRepository(dataManager: dataManager, supabaseService: supabaseService)
    private lazy var onboardingRepository: OnboardingRepositoryProtocol = LocalOnboardingRepository()
    
    // MARK: - Use Cases
    private lazy var taskUseCase: TaskUseCaseProtocol = TaskUseCase(repository: taskRepository)
    private lazy var userUseCase: UserUseCaseProtocol = UserUseCase(repository: userRepository)
    private lazy var userProfileUseCase: UserProfileUseCaseProtocol = UserProfileUseCase(repository: userProfileRepository)
    private lazy var onboardingUseCase: OnboardingUseCaseProtocol = OnboardingUseCase(repository: onboardingRepository)
    
    private init() {}
    
    // MARK: - Factory Methods
    @MainActor
    func makeTaskViewModel() -> TaskViewModel {
        return TaskViewModel()
    }
    
    @MainActor
    func makeUserViewModel() -> UserViewModel {
        return UserViewModel()
    }
    
    @MainActor
    func makeOnboardingViewModel() -> OnboardingViewModel {
        return OnboardingViewModel(repository: onboardingRepository)
    }
    
    // MARK: - Service Accessors
    @MainActor
    func getAuthenticationManager() -> AuthenticationManager {
        if _authManager == nil {
            _authManager = AuthenticationManager(supabaseService: supabaseService)
        }
        return _authManager!
    }
    
    func getSupabaseService() -> SupabaseServiceProtocol {
        return supabaseService
    }
    
    func getUserProfileRepository() -> UserProfileRepositoryProtocol {
        return userProfileRepository
    }
    
    func getUserProfileUseCase() -> UserProfileUseCaseProtocol {
        return userProfileUseCase
    }
    
    func getOnboardingRepository() -> OnboardingRepositoryProtocol {
        return onboardingRepository
    }
    
    func getOnboardingUseCase() -> OnboardingUseCaseProtocol {
        return onboardingUseCase
    }
    
    func getThemeManager() -> ThemeManager {
        return themeManager
    }
    
    func getDataManager() -> DataManagerProtocol {
        return dataManager
    }
    
    // MARK: - Configuration Methods
    func configureForTesting() {
        // Override dependencies for testing
        // Uses MockSupabaseService by default for testing
    }
    
    func configureForProduction() {
        // Switch to real Supabase service with actual credentials
        // supabaseService = SupabaseService()
        // Note: Implement SupabaseService class with real API endpoints
    }
}

// MARK: - Environment Key for SwiftUI
struct DIContainerKey: EnvironmentKey {
    static let defaultValue = DIContainer.shared
}

extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}

// MARK: - View Extension for Easy Access
extension View {
    func withDependencies() -> some View {
        self.environmentObject(DIContainer.shared.getThemeManager())
            .environment(\.diContainer, DIContainer.shared)
    }
}
