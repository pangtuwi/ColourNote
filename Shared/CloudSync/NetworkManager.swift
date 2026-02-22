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
    case notModified           // 304 - data unchanged
    case preconditionFailed(Data?)    // 412 - ETag mismatch, includes response body

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
        case .notModified:
            return "Data not modified (304)"
        case .preconditionFailed:
            return "Precondition failed - resource was modified (412)"
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

// MARK: - Response with ETag
struct ResponseWithETag<T> {
    let data: T
    let etag: String?
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

    // MARK: - Re-authentication
    private func attemptReauthentication(completion: @escaping (Bool) -> Void) {
        // Retrieve stored credentials
        guard let email = AuthManager.shared.userEmail, let password = AuthManager.shared.userPassword else {
            completion(false)
            return
        }
        // Perform login
        AuthManager.shared.login(email: email, password: password) { result in
            switch result {
            case .success:
                completion(true)
            case .failure:
                completion(false)
            }
        }
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

                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    self.attemptReauthentication { success in
                        if success {
                            var retriedRequest = request
                            if let token = self.getToken() {
                                retriedRequest.setValue("Bearer \(token)", forHTTPHeaderField: APIConfig.Headers.authorization)
                            }
                            self.session.dataTask(with: retriedRequest) { data2, response2, error2 in
                                DispatchQueue.main.async {
                                    if let error2 = error2 {
                                        completion(.failure(.networkError(error2)))
                                        return
                                    }
                                    guard let httpResponse2 = response2 as? HTTPURLResponse else {
                                        completion(.failure(.noData))
                                        return
                                    }
                                    if !(200...299).contains(httpResponse2.statusCode) {
                                        var message: String?
                                        if let data2 = data2 {
                                            message = String(data: data2, encoding: .utf8)
                                        }
                                        completion(.failure(.httpError(statusCode: httpResponse2.statusCode, message: message)))
                                        return
                                    }
                                    completion(.success(()))
                                }
                            }.resume()
                        } else {
                            if httpResponse.statusCode == 401 {
                                completion(.failure(.unauthorized))
                            } else {
                                var message: String?
                                if let data = data {
                                    message = String(data: data, encoding: .utf8)
                                }
                                completion(.failure(.httpError(statusCode: httpResponse.statusCode, message: message)))
                            }
                        }
                    }
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

                // Handle special status codes
                if httpResponse.statusCode == 304 {
                    completion(.failure(.notModified))
                    return
                }

                if httpResponse.statusCode == 412 {
                    // Include response body for conflict resolution
                    completion(.failure(.preconditionFailed(data)))
                    return
                }

                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    // Attempt re-authentication once
                    self.attemptReauthentication { success in
                        if success {
                            // Retry the original request with new token
                            var retriedRequest = request
                            if let token = self.getToken() {
                                retriedRequest.setValue("Bearer \(token)", forHTTPHeaderField: APIConfig.Headers.authorization)
                            }
                            self.performRequest(retriedRequest, completion: completion)
                        } else {
                            if httpResponse.statusCode == 401 {
                                completion(.failure(.unauthorized))
                            } else {
                                var message: String?
                                if let data = data {
                                    message = String(data: data, encoding: .utf8)
                                }
                                completion(.failure(.httpError(statusCode: httpResponse.statusCode, message: message)))
                            }
                        }
                    }
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

    /// Perform request and extract ETag from response headers
    private func performRequestWithETag<T: Decodable>(
        _ request: URLRequest,
        completion: @escaping (Result<ResponseWithETag<T>, NetworkError>) -> Void
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

                // Handle special status codes
                if httpResponse.statusCode == 304 {
                    completion(.failure(.notModified))
                    return
                }

                if httpResponse.statusCode == 412 {
                    // Include response body for conflict resolution
                    completion(.failure(.preconditionFailed(data)))
                    return
                }

                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    self.attemptReauthentication { success in
                        if success {
                            var retriedRequest = request
                            if let token = self.getToken() {
                                retriedRequest.setValue("Bearer \(token)", forHTTPHeaderField: APIConfig.Headers.authorization)
                            }
                            self.performRequestWithETag(retriedRequest, completion: completion)
                        } else {
                            if httpResponse.statusCode == 401 {
                                completion(.failure(.unauthorized))
                            } else {
                                var message: String?
                                if let data = data {
                                    message = String(data: data, encoding: .utf8)
                                }
                                completion(.failure(.httpError(statusCode: httpResponse.statusCode, message: message)))
                            }
                        }
                    }
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

                // Extract ETag from response headers
                let etag = httpResponse.value(forHTTPHeaderField: APIConfig.Headers.eTag)

                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let result = try decoder.decode(T.self, from: data)
                    completion(.success(ResponseWithETag(data: result, etag: etag)))
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

    /// GET with query parameters support
    func get<T: Decodable>(
        endpoint: String,
        queryParams: [String: String]?,
        requiresAuth: Bool = true,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        var urlString = APIConfig.baseURL + endpoint

        // Build query string from parameters
        if let params = queryParams, !params.isEmpty {
            let queryItems = params.map { key, value in
                URLQueryItem(name: key, value: value)
            }
            var components = URLComponents(string: urlString)
            components?.queryItems = queryItems
            if let fullURL = components?.url?.absoluteString {
                urlString = fullURL
            }
        }

        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HTTPMethod.GET.rawValue
        urlRequest.setValue(APIConfig.Headers.applicationJSON, forHTTPHeaderField: APIConfig.Headers.contentType)
        urlRequest.setValue(APIConfig.Headers.applicationJSON, forHTTPHeaderField: APIConfig.Headers.accept)

        // Add authorization header if required and token exists
        if requiresAuth, let token = getToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: APIConfig.Headers.authorization)
        }

        performRequest(urlRequest, completion: completion)
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

    /// PUT with ETag support for optimistic concurrency control
    func put<T: Decodable, B: Encodable>(
        endpoint: String,
        body: B,
        eTag: String?,
        requiresAuth: Bool = true,
        completion: @escaping (Result<ResponseWithETag<T>, NetworkError>) -> Void
    ) {
        guard let url = APIConfig.fullURL(for: endpoint) else {
            completion(.failure(.invalidURL))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HTTPMethod.PUT.rawValue
        urlRequest.setValue(APIConfig.Headers.applicationJSON, forHTTPHeaderField: APIConfig.Headers.contentType)
        urlRequest.setValue(APIConfig.Headers.applicationJSON, forHTTPHeaderField: APIConfig.Headers.accept)

        // Add authorization header if required and token exists
        if requiresAuth, let token = getToken() {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: APIConfig.Headers.authorization)
        }

        // Add If-Match header with ETag for optimistic concurrency
        if let etag = eTag {
            urlRequest.setValue(etag, forHTTPHeaderField: APIConfig.Headers.ifMatch)
        }

        // Encode body
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(AnyEncodable(body))
            urlRequest.httpBody = jsonData
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("NetworkManager: PUT with ETag - \(jsonString)")
            }
        } catch {
            print("NetworkManager: Encoding error - \(error)")
            completion(.failure(.encodingError(error)))
            return
        }

        performRequestWithETag(urlRequest, completion: completion)
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
