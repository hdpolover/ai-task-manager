import Foundation
import SwiftUI

// MARK: - Dependency Injection Container
class DIContainer: ObservableObject {
    
    // MARK: - Shared Instance
    static let shared = DIContainer()
    
    // MARK: - Core Services
    private lazy var dataManager: DataManagerProtocol = DataManager()
    private lazy var networkService: NetworkServiceProtocol = MockNetworkService(simulateDelay: true)
    private lazy var themeManager: ThemeManager = ThemeManager.shared
    
    // MARK: - Repositories
    private lazy var taskRepository: TaskRepositoryProtocol = LocalTaskRepository(dataManager: dataManager)
    private lazy var userRepository: UserRepositoryProtocol = LocalUserRepository(dataManager: dataManager)
    private lazy var onboardingRepository: OnboardingRepositoryProtocol = LocalOnboardingRepository()
    
    // MARK: - Use Cases
    private lazy var taskUseCase: TaskUseCaseProtocol = TaskUseCase(repository: taskRepository)
    private lazy var userUseCase: UserUseCaseProtocol = UserUseCase(repository: userRepository)
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
    
    func getNetworkService() -> NetworkServiceProtocol {
        return networkService
    }
    
    // MARK: - Configuration Methods
    func configureForTesting() {
        // Override dependencies for testing
        // This would be called in test setup
    }
    
    func configureForProduction() {
        // Configure real network service when ready
        // networkService = RealNetworkService(baseURL: URL(string: "https://api.example.com")!)
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
