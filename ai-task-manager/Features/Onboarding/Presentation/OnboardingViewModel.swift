//
//  OnboardingViewModel.swift
//  ai-task-manager
//
//  Presentation Layer - View Model for Onboarding
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Onboarding View Model
@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentPageIndex: Int = 0
    @Published var isOnboardingCompleted: Bool = false
    
    private let repository: OnboardingRepositoryProtocol
    private let pages: [OnboardingPage]
    
    // MARK: - Computed Properties
    var currentPage: OnboardingPage {
        guard currentPageIndex < pages.count else {
            return pages.last ?? OnboardingPage.pages.last!
        }
        return pages[currentPageIndex]
    }
    
    var isLastPage: Bool {
        currentPageIndex == pages.count - 1
    }
    
    var isFirstPage: Bool {
        currentPageIndex == 0
    }
    
    var progress: Double {
        guard pages.count > 0 else { return 0 }
        return Double(currentPageIndex + 1) / Double(pages.count)
    }
    
    // MARK: - Initialization
    init(repository: OnboardingRepositoryProtocol = LocalOnboardingRepository()) {
        self.repository = repository
        self.pages = repository.getOnboardingPages()
        self.isOnboardingCompleted = repository.hasCompletedOnboarding()
    }
    
    // MARK: - Actions
    func nextPage() {
        // Add haptic feedback
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            if currentPageIndex < pages.count - 1 {
                currentPageIndex += 1
            }
        }
    }
    
    func previousPage() {
        // Add haptic feedback
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            if currentPageIndex > 0 {
                currentPageIndex -= 1
            }
        }
    }
    
    func goToPage(_ index: Int) {
        // Add haptic feedback
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentPageIndex = max(0, min(index, pages.count - 1))
        }
    }
    
    func completeOnboarding() {
        // Add success haptic feedback
        #if canImport(UIKit)
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        #endif
        
        repository.markOnboardingAsCompleted()
        withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
            isOnboardingCompleted = true
        }
    }
    
    func skipOnboarding() {
        completeOnboarding()
    }
    
    func resetOnboarding() {
        repository.resetOnboarding()
        currentPageIndex = 0
        isOnboardingCompleted = false
    }
}
