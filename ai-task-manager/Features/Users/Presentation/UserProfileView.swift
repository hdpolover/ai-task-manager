//
//  UserProfileView.swift
//  ai-task-manager
//
//  User Management View
//

import SwiftUI

struct UserProfileView: View {
    @StateObject private var userViewModel = UserViewModel()
    @State private var showingAddUser = false
    @State private var showingUserDetail: User?
    
    var body: some View {
        NavigationView {
            VStack {
                // Current User Header
                if let currentUser = userViewModel.currentUser {
                    CurrentUserHeader(user: currentUser)
                        .padding()
                }
                
                // Users List
                if userViewModel.isLoading {
                    Spacer()
                    ProgressView("Loading users...")
                    Spacer()
                } else {
                    List {
                        ForEach(userViewModel.users) { user in
                            UserRowView(user: user, isCurrentUser: user.id == userViewModel.currentUser?.id) {
                                userViewModel.setCurrentUser(user)
                            }
                            .onTapGesture {
                                showingUserDetail = user
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                userViewModel.deleteUser(userViewModel.users[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Users")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add User") {
                        showingAddUser = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddUser) {
            AddUserView(userViewModel: userViewModel)
        }
        .sheet(item: $showingUserDetail) { user in
            UserDetailView(user: user, userViewModel: userViewModel)
        }
        .alert("Error", isPresented: $userViewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(userViewModel.errorMessage ?? "Unknown error occurred")
        }
    }
}

// MARK: - Current User Header
struct CurrentUserHeader: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: user.profileImageURL ?? "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current User")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(user.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - User Row View
struct UserRowView: View {
    let user: User
    let isCurrentUser: Bool
    let onSelectUser: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: user.profileImageURL ?? "person.circle.fill")
                .font(.title2)
                .foregroundColor(isCurrentUser ? .blue : .gray)
                .contentMargins(20)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user.name)
                        .font(.headline)
                    
                    if isCurrentUser {
                        Text("Current")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Joined \(user.createdAt.formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isCurrentUser {
                Button("Select") {
                    onSelectUser()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    UserProfileView()
}
