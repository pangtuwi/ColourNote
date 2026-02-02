//
//  NetworkManager.swift
//  ColourNote
//
//  Network layer for cloud sync API communication
//

import Foundation
import Security

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case encodingError(Error)
    case httpError(statusCode: Int, message: String?)
    case unauthorized
    case networkError(Error)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .httpError(let statusCode, let message):
            return "HTTP Error \(statusCode): \(message ?? "Unknown error")"
        case .unauthorized:
            return "Unauthorized - please log in again"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

// MARK: - Network Manager
class NetworkManager {

    // MARK: - Singleton
    static let shared = NetworkManager()

    // MARK: - Properties
    private let session: URLSession

    // MARK: - Initialization
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfig.Timeouts.request
        configuration.timeoutIntervalForResource = APIConfig.Timeouts.resource
        session = URLSession(configuration: configuration)
    }

    // MARK: - JWT Token Management (Keychain)

    func saveToken(_ token: String) -> Bool {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: APIConfig.KeychainKeys.jwtToken,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: APIConfig.KeychainKeys.jwtToken,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    func deleteToken() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: APIConfig.KeychainKeys.jwtToken
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    var isAuthenticated: Bool {
        return getToken() != nil
    }

    // MARK: - Generic Request Methods

    /// Performs a generic HTTP request with Codable response
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable? = nil,
        requiresAuth: Bool = true,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        guard let url = APIConfig.fullURL(for: endpoint) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(APIConfig.Headers.applicationJSON, forHTTPHeaderField: APIConfig.Headers.contentType)
        request.setValue(APIConfig.Headers.applicationJSON, forHTTPHeaderField: APIConfig.Headers.accept)

        // Add authorization header if required and token exists
        if requiresAuth, let token = getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: APIConfig.Headers.authorization)
        }

        // Encode body if present
        if let body = body {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let jsonData = try encoder.encode(AnyEncodable(body))
                request.httpBody = jsonData
                // Debug: print the JSON being sent
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("NetworkManager: Sending JSON - \(jsonString)")
                }
            } catch {
                print("NetworkManager: Encoding error - \(error)")
                completion(.failure(.encodingError(error)))
                return
            }
        }

        performRequest(request, completion: completion)
    }

    /// Performs a request that returns no response body (e.g., DELETE)
    func requestNoResponse(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable? = nil,
        requiresAuth: Bool = true,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        guard let url = APIConfig.fullURL(for: endpoint) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(APIConfig.Headers.applicationJSON, forHTTPHeaderField: APIConfig.Headers.contentType)

        // Add authorization header if required and token exists
        if requiresAuth, let token = getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: APIConfig.Headers.authorization)
        }

        // Encode body if present
        if let body = body {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let jsonData = try encoder.encode(AnyEncodable(body))
                request.httpBody = jsonData
                // Debug: print the JSON being sent
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("NetworkManager: Sending JSON - \(jsonString)")
                }
            } catch {
                print("NetworkManager: Encoding error - \(error)")
                completion(.failure(.encodingError(error)))
                return
            }
        }

        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.networkError(error)))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.noData))
                    return
                }

                if httpResponse.statusCode == 401 {
                    completion(.failure(.unauthorized))
                    return
                }

                if !(200...299).contains(httpResponse.statusCode) {
                    var message: String?
                    if let data = data {
                        message = String(data: data, encoding: .utf8)
                    }
                    completion(.failure(.httpError(statusCode: httpResponse.statusCode, message: message)))
                    return
                }

                completion(.success(()))
            }
        }.resume()
    }

    // MARK: - Private Methods

    private func performRequest<T: Decodable>(
        _ request: URLRequest,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.networkError(error)))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.noData))
                    return
                }

                if httpResponse.statusCode == 401 {
                    completion(.failure(.unauthorized))
                    return
                }

                if !(200...299).contains(httpResponse.statusCode) {
                    var message: String?
                    if let data = data {
                        message = String(data: data, encoding: .utf8)
                    }
                    completion(.failure(.httpError(statusCode: httpResponse.statusCode, message: message)))
                    return
                }

                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let result = try decoder.decode(T.self, from: data)
                    completion(.success(result))
                } catch {
                    print("NetworkManager: Decoding error - \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("NetworkManager: Raw response - \(jsonString)")
                    }
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }

    // MARK: - Convenience Methods

    func get<T: Decodable>(
        endpoint: String,
        requiresAuth: Bool = true,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        request(endpoint: endpoint, method: .GET, body: nil as String?, requiresAuth: requiresAuth, completion: completion)
    }

    func post<T: Decodable, B: Encodable>(
        endpoint: String,
        body: B,
        requiresAuth: Bool = true,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        request(endpoint: endpoint, method: .POST, body: body, requiresAuth: requiresAuth, completion: completion)
    }

    func put<T: Decodable, B: Encodable>(
        endpoint: String,
        body: B,
        requiresAuth: Bool = true,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        request(endpoint: endpoint, method: .PUT, body: body, requiresAuth: requiresAuth, completion: completion)
    }

    func delete(
        endpoint: String,
        requiresAuth: Bool = true,
        completion: @escaping (Result<Void, NetworkError>) -> Void
    ) {
        requestNoResponse(endpoint: endpoint, method: .DELETE, body: nil as String?, requiresAuth: requiresAuth, completion: completion)
    }
}

// MARK: - AnyEncodable Wrapper
// Allows encoding any Encodable type without knowing its concrete type
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        _encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
