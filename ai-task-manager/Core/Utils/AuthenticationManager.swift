//
//  AuthenticationManager.swift
//  ai-task-manager
//
//  Manages authentication state and user session
//

import Foundation
import SwiftUI

// MARK: - Authentication Manager
@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: AuthUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseService: SupabaseServiceProtocol
    
    init(supabaseService: SupabaseServiceProtocol = DIContainer.shared.getSupabaseService()) {
        self.supabaseService = supabaseService
        Task { @MainActor in
            checkAuthenticationStatus()
        }
    }
    
    // MARK: - Authentication Methods
    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Validate inputs
            guard isValidEmail(email) else {
                errorMessage = "Please enter a valid email address"
                isLoading = false
                return
            }
            
            guard password.count >= 6 else {
                errorMessage = "Password must be at least 6 characters long"
                isLoading = false
                return
            }
            
            guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = "Please enter your name"
                isLoading = false
                return
            }
            
            let authResponse = try await supabaseService.signUp(email: email, password: password)
            
            if let user = authResponse.user {
                self.currentUser = user
                self.isAuthenticated = true
                
                // Create user profile
                let profile = UserProfile(
                    name: name,
                    email: email,
                    authUserId: user.id
                )
                
                do {
                    _ = try await supabaseService.createUserProfile(profile)
                } catch {
                    print("Failed to create user profile: \(error)")
                    // Don't fail the sign up process if profile creation fails
                }
                
            } else if let error = authResponse.error {
                self.errorMessage = error.message
            }
            
        } catch {
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard isValidEmail(email) else {
                errorMessage = "Please enter a valid email address"
                isLoading = false
                return
            }
            
            guard !password.isEmpty else {
                errorMessage = "Please enter your password"
                isLoading = false
                return
            }
            
            let authResponse = try await supabaseService.signIn(email: email, password: password)
            
            if let user = authResponse.user {
                self.currentUser = user
                self.isAuthenticated = true
            } else if let error = authResponse.error {
                self.errorMessage = error.message
            }
            
        } catch {
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabaseService.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard isValidEmail(email) else {
                errorMessage = "Please enter a valid email address"
                isLoading = false
                return
            }
            
            try await supabaseService.resetPassword(email: email)
            errorMessage = "Password reset email sent. Please check your inbox."
            
        } catch {
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    private func checkAuthenticationStatus() {
        _Concurrency.Task {
            do {
                let user = try await supabaseService.getCurrentUser()
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = user != nil
                }
            } catch {
                await MainActor.run {
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    private func handleAuthError(_ error: Error) {
        if let supabaseError = error as? SupabaseError {
            self.errorMessage = supabaseError.localizedDescription
        } else {
            self.errorMessage = "An unexpected error occurred. Please try again."
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Computed Properties
    var displayName: String {
        currentUser?.email?.components(separatedBy: "@").first?.capitalized ?? "User"
    }
    
    var isSignedIn: Bool {
        isAuthenticated && currentUser != nil
    }
}
