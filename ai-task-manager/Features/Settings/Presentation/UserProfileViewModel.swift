//
//  UserProfileViewModel.swift
//  ai-task-manager
//
//  ViewModel for managing single user profile in Settings
//

import Foundation
import SwiftUI

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingEditProfile = false
    
    // Edit form properties
    @Published var editName = ""
    @Published var editEmail = ""
    @Published var editPreferences = UserPreferences()
    
    private let userProfileUseCase: UserProfileUseCaseProtocol
    
    init(userProfileUseCase: UserProfileUseCaseProtocol = DIContainer.shared.getUserProfileUseCase()) {
        self.userProfileUseCase = userProfileUseCase
        loadProfile()
    }
    
    // MARK: - Profile Management
    func loadProfile() {
        isLoading = true
        errorMessage = nil
        
        _Concurrency.Task {
            do {
                let loadedProfile = await userProfileUseCase.getProfile()
                await MainActor.run {
                    self.profile = loadedProfile
                    self.setupEditForm()
                    self.isLoading = false
                }
            }
        }
    }
    
    func createProfile(name: String, email: String) {
        isLoading = true
        errorMessage = nil
        
        _Concurrency.Task {
            let success = await userProfileUseCase.createProfile(name: name, email: email)
            
            await MainActor.run {
                if success {
                    self.loadProfile()
                } else {
                    self.errorMessage = "Failed to create profile. Please try again."
                    self.isLoading = false
                }
            }
        }
    }
    
    func updateProfile() {
        guard var currentProfile = profile else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Update profile with edited values
        currentProfile.name = editName
        currentProfile.email = editEmail
        currentProfile.preferences = editPreferences
        currentProfile.updatedAt = Date()
        
        _Concurrency.Task {
            let success = await userProfileUseCase.updateProfile(currentProfile)
            
            await MainActor.run {
                if success {
                    self.profile = currentProfile
                    self.showingEditProfile = false
                } else {
                    self.errorMessage = "Failed to update profile. Please try again."
                }
                self.isLoading = false
            }
        }
    }
    
    func updatePreferences(_ preferences: UserPreferences) {
        isLoading = true
        errorMessage = nil
        
        _Concurrency.Task {
            let success = await userProfileUseCase.updatePreferences(preferences)
            
            await MainActor.run {
                if success {
                    self.profile?.preferences = preferences
                    self.editPreferences = preferences
                } else {
                    self.errorMessage = "Failed to update preferences. Please try again."
                }
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Edit Form Management
    func startEditing() {
        setupEditForm()
        showingEditProfile = true
    }
    
    func cancelEditing() {
        setupEditForm()
        showingEditProfile = false
        errorMessage = nil
    }
    
    private func setupEditForm() {
        if let profile = profile {
            editName = profile.name
            editEmail = profile.email
            editPreferences = profile.preferences
        } else {
            editName = ""
            editEmail = ""
            editPreferences = UserPreferences()
        }
    }
    
    // MARK: - Validation
    var isFormValid: Bool {
        !editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !editEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        editEmail.contains("@")
    }
    
    // MARK: - Computed Properties
    var hasProfile: Bool {
        profile != nil
    }
    
    var displayName: String {
        profile?.name ?? "Unknown User"
    }
    
    var displayEmail: String {
        profile?.email ?? "No email"
    }
}
