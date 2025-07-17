//
//  ThemeManager.swift
//  ai-task-manager
//
//  Theme Management System for Light/Dark Mode
//

import SwiftUI
import Foundation

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            updateAppearance()
        }
    }
    
    static let shared = ThemeManager()
    
    private init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        updateAppearance()
    }
    
    private func updateAppearance() {
        DispatchQueue.main.async {
            // Update the app's color scheme
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.overrideUserInterfaceStyle = self.isDarkMode ? .dark : .light
            }
        }
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
    }
}

// MARK: - Theme Colors
extension Color {
    static let theme = ThemeColors()
}

struct ThemeColors {
    let background = Color("BackgroundColor")
    let secondaryBackground = Color("SecondaryBackgroundColor")
    let accent = Color("AccentColor")
    let text = Color("TextColor")
    let secondaryText = Color("SecondaryTextColor")
    
    // Fallback colors if custom colors aren't defined
    var adaptiveBackground: Color {
        Color(UIColor.systemBackground)
    }
    
    var adaptiveSecondaryBackground: Color {
        Color(UIColor.secondarySystemBackground)
    }
    
    var adaptiveText: Color {
        Color(UIColor.label)
    }
    
    var adaptiveSecondaryText: Color {
        Color(UIColor.secondaryLabel)
    }
}

// MARK: - Theme Environment
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}
