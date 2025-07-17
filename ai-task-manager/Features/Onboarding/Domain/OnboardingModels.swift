//
//  OnboardingModels.swift
//  ai-task-manager
//
//  Domain Models for Onboarding Feature
//

import Foundation

// MARK: - Onboarding Page Model
struct OnboardingPage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String
    let description: String
}

// MARK: - Onboarding State
enum OnboardingState {
    case notStarted
    case inProgress(currentPage: Int)
    case completed
}

// MARK: - Onboarding Use Case Protocol
protocol OnboardingUseCaseProtocol {
    func hasCompletedOnboarding() -> Bool
    func markOnboardingAsCompleted()
    func resetOnboarding()
    func getOnboardingPages() -> [OnboardingPage]
}

// MARK: - Onboarding Use Case Implementation
class OnboardingUseCase: OnboardingUseCaseProtocol {
    private let repository: OnboardingRepositoryProtocol
    
    init(repository: OnboardingRepositoryProtocol) {
        self.repository = repository
    }
    
    func hasCompletedOnboarding() -> Bool {
        return repository.hasCompletedOnboarding()
    }
    
    func markOnboardingAsCompleted() {
        repository.markOnboardingAsCompleted()
    }
    
    func resetOnboarding() {
        repository.resetOnboarding()
    }
    
    func getOnboardingPages() -> [OnboardingPage] {
        return repository.getOnboardingPages()
    }
}

// MARK: - Onboarding Data
extension OnboardingPage {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to TaskFlow",
            subtitle: "",
            imageName: "checkmark.circle.fill",
            description: "Stay organized and boost your productivity with powerful task management tools designed for teams."
        ),
        OnboardingPage(
            title: "Organize Everything",
            subtitle: "",
            imageName: "list.bullet.rectangle.portrait",
            description: "Create tasks, set priorities, and track your progress. Everything you need to stay on top of your work."
        ),
        OnboardingPage(
            title: "Work Together",
            subtitle: "",
            imageName: "person.2.circle",
            description: "Collaborate seamlessly with your team. Assign tasks, share updates, and achieve goals together."
        ),
        OnboardingPage(
            title: "Ready to Begin?",
            subtitle: "",
            imageName: "sparkles",
            description: "You're all set! Start creating your first task and experience the power of organized productivity."
        )
    ]
}
