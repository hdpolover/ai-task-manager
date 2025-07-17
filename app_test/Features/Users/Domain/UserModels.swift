import Foundation

// MARK: - User Domain Models
struct User: Identifiable, Codable {
    let id = UUID()
    var name: String
    var email: String
    var profileImageURL: String?
    var role: UserRole
    var createdAt: Date
    var isActive: Bool
    
    init(name: String, email: String, role: UserRole = .member, profileImageURL: String? = nil) {
        self.name = name
        self.email = email
        self.role = role
        self.profileImageURL = profileImageURL
        self.createdAt = Date()
        self.isActive = true
    }
}

enum UserRole: String, CaseIterable, Codable {
    case admin = "Admin"
    case manager = "Manager"
    case member = "Member"
    case guest = "Guest"
    
    var permissions: [Permission] {
        switch self {
        case .admin:
            return Permission.allCases
        case .manager:
            return [.read, .write, .update, .manageUsers]
        case .member:
            return [.read, .write, .update]
        case .guest:
            return [.read]
        }
    }
}

enum Permission: String, CaseIterable, Codable {
    case read = "Read"
    case write = "Write"
    case update = "Update"
    case delete = "Delete"
    case manageUsers = "Manage Users"
    case adminAccess = "Admin Access"
}

// MARK: - User Use Cases / Business Logic
protocol UserUseCaseProtocol {
    func getUsers() async -> [User]
    func createUser(_ user: User) async -> Bool
    func updateUser(_ user: User) async -> Bool
    func deleteUser(id: UUID) async -> Bool
    func getUserById(id: UUID) async -> User?
    func searchUsers(query: String) async -> [User]
}

class UserUseCase: UserUseCaseProtocol {
    private let repository: UserRepositoryProtocol
    
    init(repository: UserRepositoryProtocol) {
        self.repository = repository
    }
    
    func getUsers() async -> [User] {
        return await repository.fetchUsers()
    }
    
    func createUser(_ user: User) async -> Bool {
        // Business logic validation
        guard isValidEmail(user.email) else { return false }
        guard !user.name.isEmpty else { return false }
        
        return await repository.saveUser(user)
    }
    
    func updateUser(_ user: User) async -> Bool {
        guard isValidEmail(user.email) else { return false }
        return await repository.updateUser(user)
    }
    
    func deleteUser(id: UUID) async -> Bool {
        return await repository.deleteUser(id: id)
    }
    
    func getUserById(id: UUID) async -> User? {
        let users = await repository.fetchUsers()
        return users.first { $0.id == id }
    }
    
    func searchUsers(query: String) async -> [User] {
        let users = await repository.fetchUsers()
        return users.filter { user in
            user.name.localizedCaseInsensitiveContains(query) ||
            user.email.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - Private Helper Methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
