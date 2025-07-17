//
//  AddUserView.swift
//  ai-task-manager
//
//  Modal View for Adding New Users
//

import SwiftUI

struct AddUserView: View {
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var selectedIcon = "person.circle.fill"
    
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
            Form {
                Section("User Information") {
                    TextField("Full Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Email Address", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    if !userViewModel.isValidEmail(email) && email.isNotEmpty {
                        Text("Please enter a valid email address")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section("Profile Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(profileIcons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                Image(systemName: icon)
                                    .font(.title)
                                    .foregroundColor(selectedIcon == icon ? .white : .blue)
                                    .frame(width: 50, height: 50)
                                    .background(selectedIcon == icon ? Color.blue : Color.blue.opacity(0.1))
                                    .cornerRadius(25)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Preview") {
                    HStack {
                        Image(systemName: selectedIcon)
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(name.isEmpty ? "User Name" : name)
                                .font(.headline)
                            Text(email.isEmpty ? "user@example.com" : email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .navigationTitle("New User")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveUser()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        userViewModel.isValidName(name) && userViewModel.isValidEmail(email)
    }
    
    private func saveUser() {
        userViewModel.addUser(name: name, email: email, profileImageURL: selectedIcon)
        dismiss()
    }
}

#Preview {
    AddUserView(userViewModel: UserViewModel())
}
