//
//  AITaskManagerApp.swift
//  ai-task-manager
//
//  Created by MIT06 on 15/07/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct AITaskManagerApp: App {
    @StateObject private var diContainer = DIContainer.shared
    
    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .withDependencies()
                .onAppear {
                    configureApp()
                }
        }
    }
    
    private func configureApp() {
        // Configure DI container for the environment
        #if DEBUG
        // Development configuration
        print("🔧 Running in DEBUG mode")
        #else
        // Production configuration
        diContainer.configureForProduction()
        print("🚀 Running in RELEASE mode")
        #endif
        
        // Any other app-level configuration
        setupAppearance()
    }
    
    private func setupAppearance() {
        #if canImport(UIKit)
        // Customize tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Customize navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        #endif
    }
}
