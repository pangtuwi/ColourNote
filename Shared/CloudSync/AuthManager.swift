//
//  AuthManager.swift
//  ColourNote
//
//  Manages user authentication for cloud sync
//

import Foundation
import Security

// MARK: - Auth Error
enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case registrationFailed(String)
    case loginFailed(String)
    case networkError(Error)
    case tokenStorageFailed

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .registrationFailed(let message):
            return "Registration failed: \(message)"
        case .loginFailed(let message):
            return "Login failed: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .tokenStorageFailed:
            return "Failed to save authentication token"
        }
    }
}

// MARK: - Auth Manager
class AuthManager {

    // MARK: - Singleton
    static let shared = AuthManager()

    // MARK: - Properties
    private let networkManager = NetworkManager.shared

    // User email stored in Keychain
    private var _userEmail: String?

    // MARK: - Initialization
    private init() {
        _userEmail = loadUserEmail()
    }

    // MARK: - Public Properties

    /// Check if user is logged in (has valid token)
    var isLoggedIn: Bool {
        return networkManager.isAuthenticated
    }

    /// Get the logged-in user's email
    var userEmail: String? {
        return _userEmail
    }

    // MARK: - Authentication Methods

    /// Register a new user
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - completion: Callback with result
    func register(email: String, password: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        let request = AuthRequest(email: email, password: password)

        networkManager.post(
            endpoint: APIConfig.Endpoints.register,
            body: request,
            requiresAuth: false
        ) { [weak self] (result: Result<AuthResponse, NetworkError>) in
            switch result {
            case .success(let response):
                // Save token
                if self?.networkManager.saveToken(response.token) == true {
                    // Save email
                    self?.saveUserEmail(email)
                    self?._userEmail = email
                    print("AuthManager: Registration successful for \(email)")
                    completion(.success(()))
                } else {
                    completion(.failure(.tokenStorageFailed))
                }

            case .failure(let error):
                print("AuthManager: Registration failed - \(error)")
                switch error {
                case .httpError(_, let message):
                    completion(.failure(.registrationFailed(message ?? "Unknown error")))
                case .networkError(let netError):
                    completion(.failure(.networkError(netError)))
                default:
                    completion(.failure(.registrationFailed(error.localizedDescription)))
                }
            }
        }
    }

    /// Log in an existing user
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - completion: Callback with result
    func login(email: String, password: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        let request = AuthRequest(email: email, password: password)

        networkManager.post(
            endpoint: APIConfig.Endpoints.login,
            body: request,
            requiresAuth: false
        ) { [weak self] (result: Result<AuthResponse, NetworkError>) in
            switch result {
            case .success(let response):
                // Save token
                if self?.networkManager.saveToken(response.token) == true {
                    // Save email
                    self?.saveUserEmail(email)
                    self?._userEmail = email
                    print("AuthManager: Login successful for \(email)")
                    completion(.success(()))
                } else {
                    completion(.failure(.tokenStorageFailed))
                }

            case .failure(let error):
                print("AuthManager: Login failed - \(error)")
                switch error {
                case .httpError(let statusCode, let message):
                    if statusCode == 401 {
                        completion(.failure(.invalidCredentials))
                    } else {
                        completion(.failure(.loginFailed(message ?? "Unknown error")))
                    }
                case .networkError(let netError):
                    completion(.failure(.networkError(netError)))
                default:
                    completion(.failure(.loginFailed(error.localizedDescription)))
                }
            }
        }
    }

    /// Log out the current user
    func logout() {
        // Delete token from Keychain
        _ = networkManager.deleteToken()

        // Delete stored email
        deleteUserEmail()
        _userEmail = nil

        // Clear last sync time
        UserDefaults.standard.removeObject(forKey: APIConfig.UserDefaultsKeys.lastSyncTime)

        print("AuthManager: User logged out")
    }

    // MARK: - Email Storage (Keychain)

    private func saveUserEmail(_ email: String) {
        let data = email.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: APIConfig.KeychainKeys.userEmail,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("AuthManager: Failed to save user email to Keychain")
        }
    }

    private func loadUserEmail() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: APIConfig.KeychainKeys.userEmail,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let email = String(data: data, encoding: .utf8) else {
            return nil
        }

        return email
    }

    private func deleteUserEmail() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: APIConfig.KeychainKeys.userEmail
        ]
        SecItemDelete(query as CFDictionary)
    }
}
