//
//  SupabaseService.swift
//  ai-task-manager
//
//  Supabase Integration Service
//

import Foundation

// MARK: - Supabase Configuration
struct SupabaseConfig {
    static let projectUrl = "https://aduydtsgddfeyyggxgoe.supabase.co" // Replace with your Supabase project URL
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkdXlkdHNnZGRmZXl5Z2d4Z29lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI3NDE0OTIsImV4cCI6MjA2ODMxNzQ5Mn0.N6etSqPjUaAeHeoEiQSSscpTc0UDFMXLzUR4Xb2ea1w" // Replace with your Supabase anon key
}

// MARK: - Supabase Service Protocol
protocol SupabaseServiceProtocol {
    // Authentication
    func signUp(email: String, password: String) async throws -> AuthResponse
    func signIn(email: String, password: String) async throws -> AuthResponse
    func signOut() async throws
    func getCurrentUser() async throws -> AuthUser?
    func resetPassword(email: String) async throws
    
    // User Profile (Single User)
    func createUserProfile(_ profile: UserProfile) async throws -> UserProfile
    func getUserProfile() async throws -> UserProfile?
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile
    
    // Tasks
    func createTask(_ task: TaskItem) async throws -> TaskItem
    func getTasks() async throws -> [TaskItem]
    func updateTask(_ task: TaskItem) async throws -> TaskItem
    func deleteTask(id: UUID) async throws
}

// MARK: - Supabase Models
struct UserProfile: Identifiable, Codable {
    let id: UUID
    var authUserId: String? // Link to Supabase auth user
    var name: String
    var email: String
    var profileImageURL: String?
    var preferences: UserPreferences
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, email: String, authUserId: String? = nil, profileImageURL: String? = nil, preferences: UserPreferences = UserPreferences()) {
        self.id = UUID()
        self.authUserId = authUserId
        self.name = name
        self.email = email
        self.profileImageURL = profileImageURL
        self.preferences = preferences
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Authentication Models
struct AuthResponse: Codable {
    let user: AuthUser?
    let session: AuthSession?
    let error: AuthError?
}

struct AuthUser: Codable {
    let id: String
    let email: String?
    private let emailConfirmedAt: String?
    let createdAt: String
    let updatedAt: String
    
    // Computed property to check if email is confirmed
    var emailConfirmed: Bool {
        return emailConfirmedAt != nil
    }
    
    // Custom initializer for testing/mock data
    init(id: String, email: String?, emailConfirmedAt: String? = nil, createdAt: String, updatedAt: String) {
        self.id = id
        self.email = email
        self.emailConfirmedAt = emailConfirmedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case emailConfirmedAt = "email_confirmed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    let expiresAt: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case expiresAt = "expires_at"
    }
}

struct AuthError: Codable {
    let message: String
    let code: String?
}

struct SignUpRequest: Codable {
    let email: String
    let password: String
}

struct SignInRequest: Codable {
    let email: String
    let password: String
}

struct ResetPasswordRequest: Codable {
    let email: String
}

struct UserPreferences: Codable {
    var notificationsEnabled: Bool = true
    var darkModeEnabled: Bool = false
    var defaultTaskCategory: TaskCategory = .general
    var defaultTaskPriority: TaskPriority = .medium
    
    init() {}
}

// MARK: - Supabase Service Implementation
class SupabaseService: SupabaseServiceProtocol {
    private let session = URLSession.shared
    private let baseURL: URL
    private let apiKey: String
    private var currentSession: AuthSession?
    
    init() {
        guard let url = URL(string: SupabaseConfig.projectUrl) else {
            fatalError("Invalid Supabase URL")
        }
        self.baseURL = url
        self.apiKey = SupabaseConfig.anonKey
        print("🔧 SupabaseService initialized with URL: \(url)")
        print("🔑 API Key: \(apiKey.prefix(20))...")
        loadStoredSession()
    }
    
    // MARK: - Authentication Methods
    func signUp(email: String, password: String) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("auth/v1/signup")
        
        print("🔐 Attempting sign up to: \(url)")
        print("📧 Email: \(email)")
        print("🌐 Base URL: \(baseURL)")
        print("🔑 API Key prefix: \(apiKey.prefix(20))...")
        
        // First, let's test if the base URL is reachable
        do {
            let testUrl = baseURL.appendingPathComponent("rest/v1/")
            var testRequest = URLRequest(url: testUrl)
            testRequest.httpMethod = "GET"
            testRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            testRequest.setValue(apiKey, forHTTPHeaderField: "apikey")
            testRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            print("🔍 Testing Supabase connectivity to: \(testUrl)")
            let (testData, testResponse) = try await session.data(for: testRequest)
            
            if let httpTestResponse = testResponse as? HTTPURLResponse {
                print("✅ Connectivity test: HTTP \(httpTestResponse.statusCode)")
                if let testString = String(data: testData, encoding: .utf8) {
                    print("📋 Test response: \(String(testString.prefix(100)))")
                }
            }
        } catch {
            print("⚠️ Connectivity test failed: \(error)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let signUpRequest = SignUpRequest(email: email, password: password)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(signUpRequest)
        
        if let requestBody = String(data: request.httpBody!, encoding: .utf8) {
            print("� Request body: \(requestBody)")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Failed to get HTTP response")
                throw SupabaseError.requestFailed
            }
            
            print("📊 HTTP Status Code: \(httpResponse.statusCode)")
            print("📋 Response Headers: \(httpResponse.allHeaderFields)")
            print("📏 Response Data Length: \(data.count) bytes")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Response Body: \(responseString)")
                print("📝 First 50 characters: \(String(responseString.prefix(50)))")
                if responseString.contains("<html>") || responseString.contains("<!DOCTYPE") {
                    print("⚠️ WARNING: Response appears to be HTML, not JSON!")
                }
            } else {
                print("❌ Unable to decode response data as UTF-8 string")
                print("🔍 Raw bytes: \(data.map { String(format: "%02x", $0) }.joined(separator: " "))")
            }
            
            let decoder = JSONDecoder()
            
            do {
                let authResponse = try decoder.decode(AuthResponse.self, from: data)
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    if let session = authResponse.session {
                        self.currentSession = session
                        storeSession(session)
                        print("✅ Sign up successful!")
                    }
                    return authResponse
                } else {
                    if let error = authResponse.error {
                        print("❌ Sign up failed with error: \(error.message)")
                        throw SupabaseError.authenticationFailed
                    } else {
                        print("❌ Sign up failed with status code: \(httpResponse.statusCode)")
                        throw SupabaseError.authenticationFailed
                    }
                }
            } catch let decodingError {
                print("❌ JSON Decoding Error: \(decodingError)")
                print("🔍 Decoding error details:")
                if let decodingError = decodingError as? DecodingError {
                    switch decodingError {
                    case .dataCorrupted(let context):
                        print("   Data corrupted: \(context.debugDescription)")
                        if let underlyingError = context.underlyingError {
                            print("   Underlying error: \(underlyingError)")
                        }
                    case .keyNotFound(let key, let context):
                        print("   Key not found: \(key) - \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("   Type mismatch: \(type) - \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("   Value not found: \(type) - \(context.debugDescription)")
                    @unknown default:
                        print("   Unknown decoding error")
                    }
                }
                
                // Try to parse as error response
                if let errorString = String(data: data, encoding: .utf8) {
                    print("📄 Raw error response: \(errorString)")
                    
                    // Try to decode as a simple error object
                    if let errorData = errorString.data(using: .utf8) {
                        do {
                            if let errorJson = try JSONSerialization.jsonObject(with: errorData) as? [String: Any] {
                                if let message = errorJson["message"] as? String {
                                    let authError = AuthError(message: message, code: errorJson["code"] as? String)
                                    return AuthResponse(user: nil, session: nil, error: authError)
                                }
                            }
                        } catch {
                            print("❌ Failed to parse error JSON: \(error)")
                        }
                    }
                }
                throw SupabaseError.invalidResponse
            }
        } catch let networkError {
            print("❌ Network Error: \(networkError)")
            if let urlError = networkError as? URLError {
                print("   URL Error Code: \(urlError.code.rawValue)")
                print("   URL Error Description: \(urlError.localizedDescription)")
            }
            throw networkError
        }
    }
    
    func signIn(email: String, password: String) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("auth/v1/token")
            .appendingPathComponent("?grant_type=password")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        let signInRequest = SignInRequest(email: email, password: password)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(signInRequest)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.requestFailed
        }
        
        let decoder = JSONDecoder()
        let authResponse = try decoder.decode(AuthResponse.self, from: data)
        
        if httpResponse.statusCode == 200 {
            if let session = authResponse.session {
                self.currentSession = session
                storeSession(session)
            }
            return authResponse
        } else {
            throw SupabaseError.authenticationFailed
        }
    }
    
    func signOut() async throws {
        let url = baseURL.appendingPathComponent("auth/v1/logout")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        if let session = currentSession {
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 204 else {
            throw SupabaseError.requestFailed
        }
        
        clearStoredSession()
        currentSession = nil
    }
    
    func getCurrentUser() async throws -> AuthUser? {
        guard let session = currentSession else {
            return nil
        }
        
        let url = baseURL.appendingPathComponent("auth/v1/user")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.requestFailed
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(AuthUser.self, from: data)
    }
    
    func resetPassword(email: String) async throws {
        let url = baseURL.appendingPathComponent("auth/v1/recover")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        let resetRequest = ResetPasswordRequest(email: email)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(resetRequest)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.requestFailed
        }
    }
    
    // MARK: - Session Management
    private func storeSession(_ session: AuthSession) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(session) {
            UserDefaults.standard.set(data, forKey: "supabase_session")
        }
    }
    
    private func loadStoredSession() {
        guard let data = UserDefaults.standard.data(forKey: "supabase_session") else {
            return
        }
        
        let decoder = JSONDecoder()
        if let session = try? decoder.decode(AuthSession.self, from: data) {
            // Check if session is still valid
            let currentTime = Int(Date().timeIntervalSince1970)
            if session.expiresAt > currentTime {
                self.currentSession = session
            } else {
                clearStoredSession()
            }
        }
    }
    
    private func clearStoredSession() {
        UserDefaults.standard.removeObject(forKey: "supabase_session")
    }
    
    // MARK: - Helper Methods
    private func getAuthHeaders() -> [String: String] {
        var headers = [
            "Content-Type": "application/json",
            "apikey": apiKey
        ]
        
        if let session = currentSession {
            headers["Authorization"] = "Bearer \(session.accessToken)"
        } else {
            headers["Authorization"] = "Bearer \(apiKey)"
        }
        
        return headers
    }
    
    // MARK: - User Profile Methods
    func createUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        let url = baseURL.appendingPathComponent("rest/v1/user_profiles")
        
        print("👤 Creating user profile at: \(url)")
        print("   Profile: \(profile.name) - \(profile.email)")
        print("   Auth User ID: \(profile.authUserId ?? "nil")")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let headers = getAuthHeaders()
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            request.httpBody = try encoder.encode(profile)
            print("   ✅ Profile JSON encoded successfully")
        } catch {
            print("   ❌ Failed to encode profile: \(error)")
            throw error
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("   ❌ Failed to get HTTP response")
            throw SupabaseError.requestFailed
        }
        
        print("   📊 Profile creation status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("   📦 Profile response: \(responseString)")
        }
        
        guard httpResponse.statusCode == 201 else {
            print("   ❌ Profile creation failed with status: \(httpResponse.statusCode)")
            throw SupabaseError.requestFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let createdProfile = try decoder.decode([UserProfile].self, from: data)
        
        guard let profile = createdProfile.first else {
            print("   ❌ No profile returned in response")
            throw SupabaseError.invalidResponse
        }
        
        print("   ✅ Profile created successfully with ID: \(profile.id)")
        return profile
    }
    
    func getUserProfile() async throws -> UserProfile? {
        let url = baseURL.appendingPathComponent("rest/v1/user_profiles")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let headers = getAuthHeaders()
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.requestFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let profiles = try decoder.decode([UserProfile].self, from: data)
        
        return profiles.first
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        let url = baseURL.appendingPathComponent("rest/v1/user_profiles")
            .appendingPathComponent("?id=eq.\(profile.id.uuidString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        let headers = getAuthHeaders()
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        var updatedProfile = profile
        updatedProfile.updatedAt = Date()
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(updatedProfile)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.requestFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let updatedProfiles = try decoder.decode([UserProfile].self, from: data)
        
        guard let profile = updatedProfiles.first else {
            throw SupabaseError.invalidResponse
        }
        
        return profile
    }
    
    // MARK: - Task Methods
    func createTask(_ task: TaskItem) async throws -> TaskItem {
        let url = baseURL.appendingPathComponent("rest/v1/tasks")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(task)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw SupabaseError.requestFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let createdTasks = try decoder.decode([TaskItem].self, from: data)
        
        guard let task = createdTasks.first else {
            throw SupabaseError.invalidResponse
        }
        
        return task
    }
    
    func getTasks() async throws -> [TaskItem] {
        let url = baseURL.appendingPathComponent("rest/v1/tasks")
            .appendingPathComponent("?order=created_at.desc")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.requestFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([TaskItem].self, from: data)
    }
    
    func updateTask(_ task: TaskItem) async throws -> TaskItem {
        let url = baseURL.appendingPathComponent("rest/v1/tasks")
            .appendingPathComponent("?id=eq.\(task.id.uuidString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(task)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.requestFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let updatedTasks = try decoder.decode([TaskItem].self, from: data)
        
        guard let task = updatedTasks.first else {
            throw SupabaseError.invalidResponse
        }
        
        return task
    }
    
    func deleteTask(id: UUID) async throws {
        let url = baseURL.appendingPathComponent("rest/v1/tasks")
            .appendingPathComponent("?id=eq.\(id.uuidString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 204 else {
            throw SupabaseError.requestFailed
        }
    }
}

// MARK: - Mock Supabase Service for Development
class MockSupabaseService: SupabaseServiceProtocol {
    private var mockProfile: UserProfile?
    private var mockTasks: [TaskItem] = []
    private var mockCurrentUser: AuthUser?
    private var mockSession: AuthSession?
    
    // MARK: - Authentication Methods
    func signUp(email: String, password: String) async throws -> AuthResponse {
        try await _Concurrency.Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let user = AuthUser(
            id: UUID().uuidString,
            email: email,
            emailConfirmedAt: ISO8601DateFormatter().string(from: Date()), // Email confirmed immediately in mock
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        let session = AuthSession(
            accessToken: "mock_access_token_\(UUID().uuidString)",
            refreshToken: "mock_refresh_token_\(UUID().uuidString)",
            tokenType: "Bearer",
            expiresIn: 3600,
            expiresAt: Int(Date().timeIntervalSince1970) + 3600
        )
        
        mockCurrentUser = user
        mockSession = session
        
        return AuthResponse(user: user, session: session, error: nil)
    }
    
    func signIn(email: String, password: String) async throws -> AuthResponse {
        try await _Concurrency.Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        // Simulate authentication check
        if email.isEmpty || password.count < 6 {
            let error = AuthError(message: "Invalid email or password", code: "invalid_credentials")
            return AuthResponse(user: nil, session: nil, error: error)
        }
        
        let user = AuthUser(
            id: UUID().uuidString,
            email: email,
            emailConfirmedAt: ISO8601DateFormatter().string(from: Date()), // Email confirmed immediately in mock
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        let session = AuthSession(
            accessToken: "mock_access_token_\(UUID().uuidString)",
            refreshToken: "mock_refresh_token_\(UUID().uuidString)",
            tokenType: "Bearer",
            expiresIn: 3600,
            expiresAt: Int(Date().timeIntervalSince1970) + 3600
        )
        
        mockCurrentUser = user
        mockSession = session
        
        return AuthResponse(user: user, session: session, error: nil)
    }
    
    func signOut() async throws {
        try await _Concurrency.Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        mockCurrentUser = nil
        mockSession = nil
    }
    
    func getCurrentUser() async throws -> AuthUser? {
        try await _Concurrency.Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        return mockCurrentUser
    }
    
    func resetPassword(email: String) async throws {
        try await _Concurrency.Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        // Mock password reset - just simulate success
    }
    
    // MARK: - User Profile Methods
    func createUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        // Simulate network delay
        try await _Concurrency.Task.sleep(nanoseconds: 500_000_000)
        mockProfile = profile
        return profile
    }
    
    func getUserProfile() async throws -> UserProfile? {
        try await _Concurrency.Task.sleep(nanoseconds: 300_000_000)
        return mockProfile
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        try await _Concurrency.Task.sleep(nanoseconds: 400_000_000)
        mockProfile = profile
        return profile
    }
    
    // MARK: - Task Methods
    func createTask(_ task: TaskItem) async throws -> TaskItem {
        try await _Concurrency.Task.sleep(nanoseconds: 300_000_000)
        mockTasks.append(task)
        return task
    }
    
    func getTasks() async throws -> [TaskItem] {
        try await _Concurrency.Task.sleep(nanoseconds: 200_000_000)
        return mockTasks.sorted { $0.createdAt > $1.createdAt }
    }
    
    func updateTask(_ task: TaskItem) async throws -> TaskItem {
        try await _Concurrency.Task.sleep(nanoseconds: 300_000_000)
        if let index = mockTasks.firstIndex(where: { $0.id == task.id }) {
            mockTasks[index] = task
        }
        return task
    }
    
    func deleteTask(id: UUID) async throws {
        try await _Concurrency.Task.sleep(nanoseconds: 200_000_000)
        mockTasks.removeAll { $0.id == id }
    }
}

// MARK: - Supabase Errors
enum SupabaseError: LocalizedError {
    case requestFailed
    case invalidResponse
    case networkError
    case authenticationFailed
    case invalidCredentials
    case userNotFound
    case emailAlreadyExists
    case weakPassword
    case sessionExpired
    
    var errorDescription: String? {
        switch self {
        case .requestFailed:
            return "Request to Supabase failed"
        case .invalidResponse:
            return "Invalid response from Supabase"
        case .networkError:
            return "Network connection error"
        case .authenticationFailed:
            return "Authentication failed"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .weakPassword:
            return "Password must be at least 6 characters long"
        case .sessionExpired:
            return "Your session has expired. Please sign in again"
        }
    }
}
