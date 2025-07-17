//
//  AppCoordinator.swift
//  ai-task-manager
//
//  Main App Coordinator to handle navigation flow
//

import SwiftUI

struct AppCoordinator: View {
    @State private var showOnboarding = false
    @State private var showAuthenticationModal = false
    @StateObject private var authManager = AuthenticationManager()
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
                    .sheet(isPresented: $showAuthenticationModal) {
                        AuthenticationView()
                            .environmentObject(authManager)
                    }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showOnboarding)
        .environmentObject(authManager)
        .onAppear {
            checkOnboardingStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowAuthentication"))) { _ in
            showAuthenticationModal = true
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
