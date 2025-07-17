import Foundation

// MARK: - User Repository Protocol
protocol UserRepositoryProtocol {
    func fetchUsers() async -> [User]
    func saveUser(_ user: User) async -> Bool
    func updateUser(_ user: User) async -> Bool
    func deleteUser(id: UUID) async -> Bool
}

// MARK: - Local User Repository Implementation
class LocalUserRepository: UserRepositoryProtocol {
    private let dataManager: DataManagerProtocol
    
    init(dataManager: DataManagerProtocol) {
        self.dataManager = dataManager
    }
    
    func fetchUsers() async -> [User] {
        return await dataManager.loadUsers()
    }
    
    func saveUser(_ user: User) async -> Bool {
        var currentUsers = await fetchUsers()
        currentUsers.append(user)
        return await dataManager.saveUsers(currentUsers)
    }
    
    func updateUser(_ user: User) async -> Bool {
        var currentUsers = await fetchUsers()
        if let index = currentUsers.firstIndex(where: { $0.id == user.id }) {
            currentUsers[index] = user
            return await dataManager.saveUsers(currentUsers)
        }
        return false
    }
    
    func deleteUser(id: UUID) async -> Bool {
        var currentUsers = await fetchUsers()
        currentUsers.removeAll { $0.id == id }
        return await dataManager.saveUsers(currentUsers)
    }
}
