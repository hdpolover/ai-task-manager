//
//  UserDetailView.swift
//  app_test
//
//  Detailed User Information View
//

import SwiftUI

struct UserDetailView: View {
    let user: User
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var editName = ""
    @State private var editEmail = ""
    @State private var editIcon = "person.circle.fill"
    
    private let profileIcons = [
        "person.circle.fill",
        "person.crop.circle.fill",
        "person.crop.square.fill",
        "person.and.background.dotted",
        "person.2.circle.fill",
        "graduationcap.circle.fill",
        "briefcase.circle.fill",
        "heart.circle.fill"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // User Header
                    UserHeaderSection(user: user, isCurrentUser: user.id == userViewModel.currentUser?.id) {
                        userViewModel.setCurrentUser(user)
                    }
                    
                    // User Details
                    if isEditing {
                        EditUserSection(
                            name: $editName,
                            email: $editEmail,
                            selectedIcon: $editIcon,
                            profileIcons: profileIcons,
                            userViewModel: userViewModel
                        )
                    } else {
                        ViewUserSection(user: user)
                    }
                    
                    // User Statistics
                    UserStatsSection(user: user)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("User Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            saveChanges()
                        } else {
                            startEditing()
                        }
                    }
                    .disabled(isEditing && !isFormValid)
                }
                
                if isEditing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            cancelEditing()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private var isFormValid: Bool {
        userViewModel.isValidName(editName) && userViewModel.isValidEmail(editEmail)
    }
    
    private func startEditing() {
        editName = user.name
        editEmail = user.email
        editIcon = user.profileImageURL ?? "person.circle.fill"
        isEditing = true
    }
    
    private func saveChanges() {
        userViewModel.updateUser(user, name: editName, email: editEmail, profileImageURL: editIcon)
        isEditing = false
    }
    
    private func cancelEditing() {
        isEditing = false
    }
}

// MARK: - User Header Section
struct UserHeaderSection: View {
    let user: User
    let isCurrentUser: Bool
    let onSetCurrentUser: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: user.profileImageURL ?? "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text(user.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if isCurrentUser {
                    Text("Current User")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                } else {
                    Button("Set as Current User") {
                        onSetCurrentUser()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - View User Section
struct ViewUserSection: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("User Information")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                HStack {
                    Label("Name", systemImage: "person")
                    Spacer()
                    Text(user.name)
                        .fontWeight(.medium)
                }
                
                Divider()
                
                HStack {
                    Label("Email", systemImage: "envelope")
                    Spacer()
                    Text(user.email)
                        .fontWeight(.medium)
                }
                
                Divider()
                
                HStack {
                    Label("Joined", systemImage: "calendar.badge.plus")
                    Spacer()
                    Text(user.createdAt.formatted())
                        .fontWeight(.medium)
                }
                
                Divider()
                
                HStack {
                    Label("User ID", systemImage: "number")
                    Spacer()
                    Text(user.id.uuidString.prefix(8).uppercased())
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Edit User Section
struct EditUserSection: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var selectedIcon: String
    let profileIcons: [String]
    @ObservedObject var userViewModel: UserViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit User Information")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("Full Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("Email Address", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                if !userViewModel.isValidEmail(email) && email.isNotEmpty {
                    Text("Please enter a valid email address")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Text("Profile Icon")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    ForEach(profileIcons, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                        }) {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(selectedIcon == icon ? .white : .blue)
                                .frame(width: 40, height: 40)
                                .background(selectedIcon == icon ? Color.blue : Color.blue.opacity(0.1))
                                .cornerRadius(20)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - User Stats Section
struct UserStatsSection: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                StatItemView(title: "Days Active", value: "\(daysSinceJoined)", icon: "calendar")
                StatItemView(title: "Profile Views", value: "\(Int.random(in: 10...100))", icon: "eye")
                StatItemView(title: "Updates", value: "\(Int.random(in: 1...20))", icon: "arrow.clockwise")
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var daysSinceJoined: Int {
        Calendar.current.dateComponents([.day], from: user.createdAt, to: Date()).day ?? 0
    }
}

// MARK: - Stat Item View
struct StatItemView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    UserDetailView(
        user: User(name: "John Doe", email: "john@example.com"),
        userViewModel: UserViewModel()
    )
}
