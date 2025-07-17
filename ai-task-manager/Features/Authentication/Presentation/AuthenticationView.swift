//
//  AuthenticationView.swift
//  ai-task-manager
//
//  Sign in and sign up views
//

import SwiftUI

// MARK: - Authentication Container View
struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if showingSignUp {
                    SignUpView(authManager: authManager)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                } else {
                    SignInView(authManager: authManager)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading),
                            removal: .move(edge: .trailing)
                        ))
                }
                
                // Toggle between Sign In and Sign Up
                HStack {
                    Text(showingSignUp ? "Already have an account?" : "Don't have an account?")
                        .foregroundColor(.secondary)
                    
                    Button(showingSignUp ? "Sign In" : "Sign Up") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingSignUp.toggle()
                        }
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
                }
                .padding()
                .background(Color(.systemGray6))
            }
        }
        .environmentObject(authManager)
    }
}

// MARK: - Sign In View
struct SignInView: View {
    @ObservedObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var showingForgotPassword = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Welcome Back")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign in to your AI Task Manager account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("Enter your email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .email)
                            .textFieldStyle(RoundedTextFieldStyle())
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        SecureField("Enter your password", text: $password)
                            .focused($focusedField, equals: .password)
                            .textFieldStyle(RoundedTextFieldStyle())
                    }
                    
                    // Forgot Password
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            showingForgotPassword = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // Sign In Button
                Button(action: signIn) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(canSignIn ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!canSignIn || authManager.isLoading)
                .padding(.horizontal)
                
                // Error Message
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onSubmit {
            switch focusedField {
            case .email:
                focusedField = .password
            case .password:
                if canSignIn {
                    signIn()
                }
            case .none:
                break
            }
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView(authManager: authManager)
        }
    }
    
    private var canSignIn: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func signIn() {
        focusedField = nil
        _Concurrency.Task {
            await authManager.signIn(email: email, password: password)
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @ObservedObject var authManager: AuthenticationManager
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, password, confirmPassword
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Join AI Task Manager and boost your productivity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 16) {
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("Enter your full name", text: $name)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .name)
                            .textFieldStyle(RoundedTextFieldStyle())
                    }
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("Enter your email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .email)
                            .textFieldStyle(RoundedTextFieldStyle())
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        SecureField("Create a password", text: $password)
                            .focused($focusedField, equals: .password)
                            .textFieldStyle(RoundedTextFieldStyle())
                    }
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        SecureField("Confirm your password", text: $confirmPassword)
                            .focused($focusedField, equals: .confirmPassword)
                            .textFieldStyle(RoundedTextFieldStyle())
                        
                        if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("Passwords don't match")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Sign Up Button
                Button(action: signUp) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Text("Create Account")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(canSignUp ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!canSignUp || authManager.isLoading)
                .padding(.horizontal)
                
                // Error Message
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onSubmit {
            switch focusedField {
            case .name:
                focusedField = .email
            case .email:
                focusedField = .password
            case .password:
                focusedField = .confirmPassword
            case .confirmPassword:
                if canSignUp {
                    signUp()
                }
            case .none:
                break
            }
        }
    }
    
    private var canSignUp: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty && 
        password == confirmPassword && password.count >= 6
    }
    
    private func signUp() {
        focusedField = nil
        _Concurrency.Task {
            await authManager.signUp(email: email, password: password, name: name)
        }
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @ObservedObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var emailSent = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "envelope.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Reset Password")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your email address and we'll send you a link to reset your password.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                if !emailSent {
                    VStack(spacing: 16) {
                        TextField("Enter your email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                            .textFieldStyle(RoundedTextFieldStyle())
                        
                        Button("Send Reset Link") {
                            sendResetEmail()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(email.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(email.isEmpty || authManager.isLoading)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        
                        Text("Email Sent!")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Check your inbox for password reset instructions.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendResetEmail() {
        _Concurrency.Task {
            await authManager.resetPassword(email: email)
            await MainActor.run {
                if authManager.errorMessage?.contains("sent") == true {
                    emailSent = true
                }
            }
        }
    }
}

// MARK: - Custom Text Field Style
struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

#Preview {
    AuthenticationView()
}
