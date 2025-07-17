import Foundation

// MARK: - Network Service Protocol
protocol NetworkServiceProtocol {
    func fetchTasks() async throws -> [TaskItem]
    func createTask(_ task: TaskItem) async throws -> TaskItem
    func updateTask(_ task: TaskItem) async throws -> TaskItem
    func deleteTask(id: UUID) async throws -> Bool
    
    func fetchUsers() async throws -> [User]
    func createUser(_ user: User) async throws -> User
    func updateUser(_ user: User) async throws -> User
    func deleteUser(id: UUID) async throws -> Bool
}

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(Int)
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .networkUnavailable:
            return "Network unavailable"
        }
    }
}

// MARK: - Mock Network Service Implementation
class MockNetworkService: NetworkServiceProtocol {
    private let simulateDelay: Bool
    private let shouldFail: Bool
    
    init(simulateDelay: Bool = true, shouldFail: Bool = false) {
        self.simulateDelay = simulateDelay
        self.shouldFail = shouldFail
    }
    
    // MARK: - Task Network Operations
    func fetchTasks() async throws -> [TaskItem] {
        if simulateDelay {
            try await _Concurrency.Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        if shouldFail {
            throw NetworkError.serverError(500)
        }
        
        return [
            TaskItem(title: "Remote Task 1", description: "Fetched from server", priority: .high),
            TaskItem(title: "Remote Task 2", description: "Another server task", priority: .medium)
        ]
    }
    
    func createTask(_ task: TaskItem) async throws -> TaskItem {
        if simulateDelay {
            try await _Concurrency.Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        if shouldFail {
            throw NetworkError.serverError(400)
        }
        
        return task
    }
    
    func updateTask(_ task: TaskItem) async throws -> TaskItem {
        if simulateDelay {
            try await _Concurrency.Task.sleep(nanoseconds: 500_000_000)
        }
        
        if shouldFail {
            throw NetworkError.serverError(400)
        }
        
        return task
    }
    
    func deleteTask(id: UUID) async throws -> Bool {
        if simulateDelay {
            try await _Concurrency.Task.sleep(nanoseconds: 500_000_000)
        }
        
        if shouldFail {
            throw NetworkError.serverError(404)
        }
        
        return true
    }
    
    // MARK: - User Network Operations
    func fetchUsers() async throws -> [User] {
        if simulateDelay {
            try await _Concurrency.Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        if shouldFail {
            throw NetworkError.serverError(500)
        }
        
        return [
            User(name: "Remote User 1", email: "user1@server.com", role: .admin),
            User(name: "Remote User 2", email: "user2@server.com", role: .member)
        ]
    }
    
    func createUser(_ user: User) async throws -> User {
        if simulateDelay {
            try await _Concurrency.Task.sleep(nanoseconds: 500_000_000)
        }
        
        if shouldFail {
            throw NetworkError.serverError(400)
        }
        
        return user
    }
    
    func updateUser(_ user: User) async throws -> User {
        if simulateDelay {
            try await _Concurrency.Task.sleep(nanoseconds: 500_000_000)
        }
        
        if shouldFail {
            throw NetworkError.serverError(400)
        }
        
        return user
    }
    
    func deleteUser(id: UUID) async throws -> Bool {
        if simulateDelay {
            try await _Concurrency.Task.sleep(nanoseconds: 500_000_000)
        }
        
        if shouldFail {
            throw NetworkError.serverError(404)
        }
        
        return true
    }
}

// MARK: - Real Network Service Implementation (for future use)
class RealNetworkService: NetworkServiceProtocol {
    private let baseURL: URL
    private let session: URLSession
    
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    // MARK: - Generic Network Request Method
    private func performRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError(0)
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(responseType, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    // MARK: - Task Network Operations
    func fetchTasks() async throws -> [TaskItem] {
        return try await performRequest(endpoint: "/tasks", responseType: [TaskItem].self)
    }
    
    func createTask(_ task: TaskItem) async throws -> TaskItem {
        let data = try JSONEncoder().encode(task)
        return try await performRequest(endpoint: "/tasks", method: .POST, body: data, responseType: TaskItem.self)
    }
    
    func updateTask(_ task: TaskItem) async throws -> TaskItem {
        let data = try JSONEncoder().encode(task)
        return try await performRequest(endpoint: "/tasks/\(task.id)", method: .PUT, body: data, responseType: TaskItem.self)
    }
    
    func deleteTask(id: UUID) async throws -> Bool {
        let _: EmptyResponse = try await performRequest(endpoint: "/tasks/\(id)", method: .DELETE, responseType: EmptyResponse.self)
        return true
    }
    
    // MARK: - User Network Operations
    func fetchUsers() async throws -> [User] {
        return try await performRequest(endpoint: "/users", responseType: [User].self)
    }
    
    func createUser(_ user: User) async throws -> User {
        let data = try JSONEncoder().encode(user)
        return try await performRequest(endpoint: "/users", method: .POST, body: data, responseType: User.self)
    }
    
    func updateUser(_ user: User) async throws -> User {
        let data = try JSONEncoder().encode(user)
        return try await performRequest(endpoint: "/users/\(user.id)", method: .PUT, body: data, responseType: User.self)
    }
    
    func deleteUser(id: UUID) async throws -> Bool {
        let _: EmptyResponse = try await performRequest(endpoint: "/users/\(id)", method: .DELETE, responseType: EmptyResponse.self)
        return true
    }
}

// MARK: - Supporting Types
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

struct EmptyResponse: Codable {}
