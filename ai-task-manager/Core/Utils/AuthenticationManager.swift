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
        print("🚀 Starting sign up process...")
        print("   Called with email: \(email), name: \(name)")
        isLoading = true
        errorMessage = nil
        
        do {
            // Validate inputs
            guard isValidEmail(email) else {
                errorMessage = "Please enter a valid email address"
                isLoading = false
                print("❌ Invalid email address")
                return
            }
            
            guard password.count >= 6 else {
                errorMessage = "Password must be at least 6 characters long"
                isLoading = false
                print("❌ Password too short")
                return
            }
            
            guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = "Please enter your name"
                isLoading = false
                print("❌ Name is empty")
                return
            }
            
            print("✅ Input validation passed")
            
            let authResponse = try await supabaseService.signUp(email: email, password: password)
            
            print("📝 Received auth response")
            
            if let user = authResponse.user {
                print("✅ User created successfully: \(user.id)")
                print("   Email confirmed: \(user.emailConfirmed)")
                
                if user.emailConfirmed {
                    // User is fully confirmed and can be signed in
                    self.currentUser = user
                    self.isAuthenticated = true
                    
                    // Create user profile
                    let profile = UserProfile(
                        name: name,
                        email: email,
                        authUserId: user.id
                    )
                    
                    print("👤 Creating user profile...")
                    do {
                        _ = try await supabaseService.createUserProfile(profile)
                        print("✅ User profile created successfully")
                    } catch {
                        print("❌ Failed to create user profile: \(error)")
                        // Don't fail the sign up process if profile creation fails
                    }
                } else {
                    // Email confirmation required
                    print("📧 Email confirmation required")
                    self.errorMessage = "Please check your email and click the confirmation link to complete your registration."
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
                
            } else if let error = authResponse.error {
                print("❌ Auth response contains error: \(error.message)")
                self.errorMessage = error.message
            } else {
                print("❌ No user or error in auth response")
                print("   Auth response user: \(String(describing: authResponse.user))")
                print("   Auth response error: \(String(describing: authResponse.error))")
                self.errorMessage = "Unknown error occurred during sign up"
            }
            
        } catch {
            print("❌ Sign up failed with error: \(error)")
            handleAuthError(error)
        }
        
        isLoading = false
        print("🏁 Sign up process completed")
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
        print("🚨 Authentication Error Details:")
        print("   Error Type: \(type(of: error))")
        print("   Error Description: \(error.localizedDescription)")
        
        if let supabaseError = error as? SupabaseError {
            print("   Supabase Error: \(supabaseError)")
            self.errorMessage = supabaseError.localizedDescription
        } else if let urlError = error as? URLError {
            print("   URL Error Code: \(urlError.code)")
            print("   URL Error Description: \(urlError.localizedDescription)")
            switch urlError.code {
            case .notConnectedToInternet:
                self.errorMessage = "No internet connection. Please check your network."
            case .timedOut:
                self.errorMessage = "Request timed out. Please try again."
            case .cannotConnectToHost:
                self.errorMessage = "Cannot connect to server. Please try again later."
            default:
                self.errorMessage = "Network error: \(urlError.localizedDescription)"
            }
        } else {
            print("   Generic Error: \(error)")
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
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
