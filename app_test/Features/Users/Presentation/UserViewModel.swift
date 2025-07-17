//
//  UserViewModel.swift
//  app_test
//
//  Clean Architecture - ViewModel Layer for User Management
//

import Foundation
import SwiftUI

// MARK: - User View Model
@MainActor
class UserViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var users: [User] = []
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    
    // MARK: - Dependencies
    private let dataManager: DataManagerProtocol
    
    // MARK: - Initialization
    init(dataManager: DataManagerProtocol = DataManager()) {
        self.dataManager = dataManager
        loadUsers()
        setDefaultUser()
    }
    
    // MARK: - User Management Functions
    func addUser(name: String, email: String, profileImageURL: String? = nil) {
        let newUser = User(name: name, email: email, profileImageURL: profileImageURL)
        users.append(newUser)
        
        // Set as current user if it's the first user
        if currentUser == nil {
            currentUser = newUser
        }
        
        saveUsers()
    }
    
    func updateUser(_ user: User, name: String, email: String, profileImageURL: String?) {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index].name = name
            users[index].email = email
            users[index].profileImageURL = profileImageURL
            
            // Update current user if it's the one being edited
            if currentUser?.id == user.id {
                currentUser = users[index]
            }
            
            saveUsers()
        }
    }
    
    func deleteUser(_ user: User) {
        users.removeAll { $0.id == user.id }
        
        // Reset current user if deleted
        if currentUser?.id == user.id {
            currentUser = users.first
        }
        
        saveUsers()
    }
    
    func setCurrentUser(_ user: User) {
        currentUser = user
    }
    
        // MARK: - Data Persistence
    private func saveUsers() {
        _Concurrency.Task {
            let success = await dataManager.saveUsers(users)
            if !success {
                handleError(DataError.saveFailed)
            }
        }
    }
    
    private func loadUsers() {
        _Concurrency.Task {
            isLoading = true
            users = await dataManager.loadUsers()
            if let firstUser = users.first {
                currentUser = firstUser
            }
            isLoading = false
        }
    }
    
    // MARK: - Default Setup
    private func setDefaultUser() {
        if users.isEmpty {
            addUser(name: "John Doe", email: "john@example.com", profileImageURL: "person.circle.fill")
        }
    }
    
    // MARK: - Computed Properties
    var userCount: Int {
        users.count
    }
    
    var hasCurrentUser: Bool {
        currentUser != nil
    }
    
    // MARK: - Validation
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func isValidName(_ name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && name.count >= 2
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
}

// MARK: - Data Errors
enum DataError: LocalizedError {
    case saveFailed
    case loadFailed
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save data"
        case .loadFailed:
            return "Failed to load data"
        }
    }
}
