//
//  MockNetworkManager.swift
//  ColourNoteXCTests
//
//  Fully offline NetworkManaging mock for Auth and sync service tests.
//

import Foundation
@testable import ColourNote

final class MockNetworkManager: NetworkManaging {

    // MARK: - Recorded Calls
    var calledEndpoints: [String] = []
    var lastBody: (any Encodable)?

    // MARK: - Configurable Stubs
    var stubbedGETData: (any Decodable)?
    var stubbedGETError: NetworkError?
    var stubbedPOSTData: (any Decodable)?
    var stubbedPOSTError: NetworkError?
    var stubbedPUTData: (any Decodable)?
    var stubbedPUTError: NetworkError?
    var stubbedDELETEError: NetworkError?
    var stubbedToken: String? = "mock-jwt-token"
    var stubbedIsAuthenticated: Bool = true

    // MARK: - NetworkManaging

    var isAuthenticated: Bool { stubbedIsAuthenticated }

    func get<T: Decodable>(endpoint: String, requiresAuth: Bool,
                           completion: @escaping (Result<T, NetworkError>) -> Void) {
        calledEndpoints.append(endpoint)
        if let error = stubbedGETError {
            completion(.failure(error)); return
        }
        if let data = stubbedGETData as? T {
            completion(.success(data)); return
        }
        completion(.failure(.noData))
    }

    func get<T: Decodable>(endpoint: String, queryParams: [String: String]?,
                           requiresAuth: Bool,
                           completion: @escaping (Result<T, NetworkError>) -> Void) {
        calledEndpoints.append(endpoint)
        if let error = stubbedGETError {
            completion(.failure(error)); return
        }
        if let data = stubbedGETData as? T {
            completion(.success(data)); return
        }
        completion(.failure(.noData))
    }

    func post<T: Decodable, B: Encodable>(endpoint: String, body: B, requiresAuth: Bool,
                                          completion: @escaping (Result<T, NetworkError>) -> Void) {
        calledEndpoints.append(endpoint)
        lastBody = body
        if let error = stubbedPOSTError {
            completion(.failure(error)); return
        }
        if let data = stubbedPOSTData as? T {
            completion(.success(data)); return
        }
        completion(.failure(.noData))
    }

    func put<T: Decodable, B: Encodable>(endpoint: String, body: B, requiresAuth: Bool,
                                         completion: @escaping (Result<T, NetworkError>) -> Void) {
        calledEndpoints.append(endpoint)
        lastBody = body
        if let error = stubbedPUTError {
            completion(.failure(error)); return
        }
        if let data = stubbedPUTData as? T {
            completion(.success(data)); return
        }
        completion(.failure(.noData))
    }

    func put<T: Decodable, B: Encodable>(endpoint: String, body: B, eTag: String?,
                                         requiresAuth: Bool,
                                         completion: @escaping (Result<ResponseWithETag<T>, NetworkError>) -> Void) {
        calledEndpoints.append(endpoint)
        lastBody = body
        if let error = stubbedPUTError {
            completion(.failure(error)); return
        }
        if let data = stubbedPUTData as? T {
            completion(.success(ResponseWithETag(data: data, etag: nil))); return
        }
        completion(.failure(.noData))
    }

    func delete(endpoint: String, requiresAuth: Bool,
                completion: @escaping (Result<Void, NetworkError>) -> Void) {
        calledEndpoints.append(endpoint)
        if let error = stubbedDELETEError {
            completion(.failure(error)); return
        }
        completion(.success(()))
    }

    func requestNoResponse(endpoint: String, method: HTTPMethod, body: (any Encodable)?,
                           requiresAuth: Bool,
                           completion: @escaping (Result<Void, NetworkError>) -> Void) {
        calledEndpoints.append(endpoint)
        lastBody = body
        if let error = stubbedDELETEError {
            completion(.failure(error)); return
        }
        completion(.success(()))
    }

    // MARK: - Token Management

    func saveToken(_ token: String) -> Bool {
        stubbedToken = token
        return true
    }

    func getToken() -> String? { stubbedToken }

    func deleteToken() -> Bool {
        stubbedToken = nil
        return true
    }
}
