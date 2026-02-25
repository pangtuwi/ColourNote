//
//  NetworkManagerTests.swift
//  ColourNoteXCTests
//
//  Tests for NetworkManager token/keychain operations and HTTP request construction.
//  Token tests use the real Keychain (available in simulator).
//  HTTP tests use NetworkManager(session:) with MockURLProtocol — not the singleton.
//

import Testing
import Foundation
@testable import ColourNote

@Suite(.serialized)
struct NetworkManagerTests {

    // MARK: - Helpers

    /// Create a fresh NetworkManager backed by MockURLProtocol.
    private func makeSUT() -> NetworkManager {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        return NetworkManager(session: session)
    }

    // MARK: - Token / Keychain Tests

    @Test func tokenRoundTrip() {
        let sut = makeSUT()
        // Clean slate
        _ = sut.deleteToken()

        _ = sut.saveToken("hello-token")
        #expect(sut.getToken() == "hello-token")

        _ = sut.deleteToken()
        #expect(sut.getToken() == nil)
    }

    @Test func isAuthenticatedTrueWhenTokenPresent() {
        let sut = makeSUT()
        _ = sut.deleteToken()
        _ = sut.saveToken("bearer-xyz")
        #expect(sut.isAuthenticated == true)
        _ = sut.deleteToken()
    }

    @Test func isAuthenticatedFalseWhenNoToken() {
        let sut = makeSUT()
        _ = sut.deleteToken()
        #expect(sut.isAuthenticated == false)
    }

    // MARK: - HTTP Tests (URLProtocol)

    @Test func getDecodesSuccessResponse() async {
        let sut = makeSUT()
        let notes = [TestFixtures.makeCloudNote()]
        let data = TestFixtures.encode(notes)
        let url = URL(string: APIConfig.baseURL + APIConfig.Endpoints.notes)!

        MockURLProtocol.requestHandler = { _ in
            (TestFixtures.httpResponse(status: 200, url: url), data)
        }

        let result: Result<[CloudNote], NetworkError> = await withCheckedContinuation { cont in
            sut.get(endpoint: APIConfig.Endpoints.notes, requiresAuth: false) { (r: Result<[CloudNote], NetworkError>) in
                cont.resume(returning: r)
            }
        }

        switch result {
        case .success(let decoded):
            #expect(decoded.count == 1)
            #expect(decoded.first?.title == "Cloud Note")
        case .failure(let error):
            Issue.record("Expected success, got \(error)")
        }
    }

    @Test func getReturnsNotModifiedError() async {
        let sut = makeSUT()
        let url = URL(string: APIConfig.baseURL + APIConfig.Endpoints.notes)!

        MockURLProtocol.requestHandler = { _ in
            (TestFixtures.httpResponse(status: 304, url: url), Data())
        }

        let result: Result<[CloudNote], NetworkError> = await withCheckedContinuation { cont in
            sut.get(endpoint: APIConfig.Endpoints.notes, requiresAuth: false) { (r: Result<[CloudNote], NetworkError>) in
                cont.resume(returning: r)
            }
        }

        if case .failure(.notModified) = result {
            // expected
        } else {
            Issue.record("Expected .failure(.notModified), got \(result)")
        }
    }

    @Test func postSendsAuthorizationHeaderWhenTokenExists() async {
        let sut = makeSUT()
        _ = sut.deleteToken()
        _ = sut.saveToken("test-bearer-token")

        let url = URL(string: APIConfig.baseURL + APIConfig.Endpoints.login)!
        var capturedRequest: URLRequest?

        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = TestFixtures.makeAuthResponse()
            let data = TestFixtures.encode(response)
            return (TestFixtures.httpResponse(status: 200, url: url), data)
        }

        let body = AuthRequest(email: "test@example.com", password: "secret")
        let _: Result<AuthResponse, NetworkError> = await withCheckedContinuation { cont in
            sut.post(endpoint: APIConfig.Endpoints.login, body: body, requiresAuth: true) { (r: Result<AuthResponse, NetworkError>) in
                cont.resume(returning: r)
            }
        }

        let authHeader = capturedRequest?.value(forHTTPHeaderField: "Authorization")
        #expect(authHeader == "Bearer test-bearer-token")

        _ = sut.deleteToken()
    }
}
