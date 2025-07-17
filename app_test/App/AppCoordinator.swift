//
//  AppCoordinator.swift
//  app_test
//
//  Main App Coordinator to handle navigation flow
//

import SwiftUI

struct AppCoordinator: View {
    @State private var showOnboarding = false
    @Environment(\.diContainer) private var diContainer
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView {
                    showOnboarding = false
                }
                .transition(.opacity.combined(with: .scale))
            } else {
                ContentView()
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showOnboarding)
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
