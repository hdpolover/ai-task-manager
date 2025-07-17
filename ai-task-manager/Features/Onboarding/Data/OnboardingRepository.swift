//
//  OnboardingRepository.swift
//  ai-task-manager
//
//  Data Layer for Onboarding Feature
//

import Foundation

// MARK: - Onboarding Repository Protocol
protocol OnboardingRepositoryProtocol {
    func hasCompletedOnboarding() -> Bool
    func markOnboardingAsCompleted()
    func resetOnboarding()
    func getOnboardingPages() -> [OnboardingPage]
}

// MARK: - Local Onboarding Repository
class LocalOnboardingRepository: OnboardingRepositoryProtocol {
    private let userDefaults: UserDefaults
    private let onboardingCompletedKey = "hasCompletedOnboarding"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func hasCompletedOnboarding() -> Bool {
        return userDefaults.bool(forKey: onboardingCompletedKey)
    }
    
    func markOnboardingAsCompleted() {
        userDefaults.set(true, forKey: onboardingCompletedKey)
    }
    
    func resetOnboarding() {
        userDefaults.removeObject(forKey: onboardingCompletedKey)
    }
    
    func getOnboardingPages() -> [OnboardingPage] {
        return OnboardingPage.pages
    }
}

// MARK: - Mock Repository for Testing
class MockOnboardingRepository: OnboardingRepositoryProtocol {
    private var isCompleted: Bool = false
    
    func hasCompletedOnboarding() -> Bool {
        return isCompleted
    }
    
    func markOnboardingAsCompleted() {
        isCompleted = true
    }
    
    func resetOnboarding() {
        isCompleted = false
    }
    
    func getOnboardingPages() -> [OnboardingPage] {
        return OnboardingPage.pages
    }
}
