//
//  UserProfileRepository.swift
//  ai-task-manager
//
//  Repository for single user profile management with Supabase integration
//

import Foundation

// MARK: - User Profile Repository Protocol
protocol UserProfileRepositoryProtocol {
    func createProfile(_ profile: UserProfile) async -> Bool
    func fetchProfile() async -> UserProfile?
    func updateProfile(_ profile: UserProfile) async -> Bool
    func deleteProfile() async -> Bool
}

// MARK: - User Profile Repository Implementation
class UserProfileRepository: UserProfileRepositoryProtocol {
    private let dataManager: DataManagerProtocol
    private let supabaseService: SupabaseServiceProtocol
    
    init(dataManager: DataManagerProtocol, supabaseService: SupabaseServiceProtocol = MockSupabaseService()) {
        self.dataManager = dataManager
        self.supabaseService = supabaseService
    }
    
    func createProfile(_ profile: UserProfile) async -> Bool {
        do {
            // Create in Supabase first
            _ = try await supabaseService.createUserProfile(profile)
            
            // Save locally as backup
            return await dataManager.saveUserProfile(profile)
        } catch {
            print("Failed to create profile in Supabase: \(error)")
            // Save locally even if remote fails
            return await dataManager.saveUserProfile(profile)
        }
    }
    
    func fetchProfile() async -> UserProfile? {
        return await dataManager.loadUserProfile()
    }
    
    func updateProfile(_ profile: UserProfile) async -> Bool {
        do {
            // Update in Supabase first
            _ = try await supabaseService.updateUserProfile(profile)
            
            // Update locally
            return await dataManager.saveUserProfile(profile)
        } catch {
            print("Failed to update profile in Supabase: \(error)")
            // Update locally even if remote fails
            return await dataManager.saveUserProfile(profile)
        }
    }
    
    func deleteProfile() async -> Bool {
        // For single user app, we'll just clear the local data
        // In a multi-user app, you'd also delete from Supabase
        return await dataManager.saveUserProfile(UserProfile(name: "", email: ""))
    }
}

// MARK: - User Profile Use Case
protocol UserProfileUseCaseProtocol {
    func createProfile(name: String, email: String) async -> Bool
    func getProfile() async -> UserProfile?
    func updateProfile(_ profile: UserProfile) async -> Bool
    func updatePreferences(_ preferences: UserPreferences) async -> Bool
    func deleteProfile() async -> Bool
}

class UserProfileUseCase: UserProfileUseCaseProtocol {
    private let repository: UserProfileRepositoryProtocol
    
    init(repository: UserProfileRepositoryProtocol) {
        self.repository = repository
    }
    
    func createProfile(name: String, email: String) async -> Bool {
        // Validate input
        guard !name.isEmpty, isValidEmail(email) else {
            return false
        }
        
        let profile = UserProfile(name: name, email: email)
        return await repository.createProfile(profile)
    }
    
    func getProfile() async -> UserProfile? {
        return await repository.fetchProfile()
    }
    
    func updateProfile(_ profile: UserProfile) async -> Bool {
        // Validate input
        guard !profile.name.isEmpty, isValidEmail(profile.email) else {
            return false
        }
        
        return await repository.updateProfile(profile)
    }
    
    func updatePreferences(_ preferences: UserPreferences) async -> Bool {
        guard var profile = await repository.fetchProfile() else {
            return false
        }
        
        profile.preferences = preferences
        profile.updatedAt = Date()
        
        return await repository.updateProfile(profile)
    }
    
    func deleteProfile() async -> Bool {
        return await repository.deleteProfile()
    }
    
    // MARK: - Private Helper Methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
