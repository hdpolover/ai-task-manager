//
//  AppCoordinator.swift
//  ai-task-manager
//
//  Main App Coordinator to handle navigation flow
//

import SwiftUI

struct AppCoordinator: View {
    @State private var showOnboarding = false
    @StateObject private var authManager = AuthenticationManager()
    @Environment(\.diContainer) private var diContainer
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView {
                    showOnboarding = false
                }
                .transition(.opacity.combined(with: .scale))
            } else if authManager.isAuthenticated {
                ContentView()
                    .transition(.opacity.combined(with: .scale))
            } else {
                AuthenticationView()
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showOnboarding)
        .animation(.easeInOut(duration: 0.5), value: authManager.isAuthenticated)
        .environmentObject(authManager)
        .onAppear {
            checkOnboardingStatus()
        }
    }
    
    private func checkOnboardingStatus() {
        let repository = diContainer.getOnboardingRepository()
        showOnboarding = !repository.hasCompletedOnboarding()
    }
}

#Preview {
    AppCoordinator()
        .withDependencies()
}
