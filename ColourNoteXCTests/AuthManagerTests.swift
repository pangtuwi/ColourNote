//
//  AuthManagerTests.swift
//  ColourNoteXCTests
//
//  Tests for AuthManager using MockNetworkManager — fully offline.
//

import Testing
import Foundation
@testable import ColourNote

struct AuthManagerTests {

    private func makeSUT() -> (AuthManager, MockNetworkManager) {
        let mock = MockNetworkManager()
        let auth = AuthManager(networkManager: mock)
        return (auth, mock)
    }

    // MARK: - Login Tests

    @Test func loginSuccessStoresToken() async {
        let (auth, mock) = makeSUT()
        mock.stubbedPOSTData = TestFixtures.makeAuthResponse(token: "login-jwt-token")

        let result: Result<Void, AuthError> = await withCheckedContinuation { cont in
            auth.login(email: "user@example.com", password: "pass123") { r in
                cont.resume(returning: r)
            }
        }

        if case .failure(let e) = result { Issue.record("Expected success, got \(e)"); return }
        #expect(mock.stubbedToken == "login-jwt-token")
    }

    @Test func loginFailsWith401ReturnsInvalidCredentials() async {
        let (auth, mock) = makeSUT()
        mock.stubbedPOSTError = .httpError(statusCode: 401, message: "Unauthorized")

        let result: Result<Void, AuthError> = await withCheckedContinuation { cont in
            auth.login(email: "user@example.com", password: "wrong") { r in
                cont.resume(returning: r)
            }
        }

        if case .failure(.invalidCredentials) = result {
            // expected
        } else {
            Issue.record("Expected .invalidCredentials, got \(result)")
        }
    }

    @Test func loginFailsOnNetworkErrorPropagatesError() async {
        let (auth, mock) = makeSUT()
        let underlying = URLError(.notConnectedToInternet)
        mock.stubbedPOSTError = .networkError(underlying)

        let result: Result<Void, AuthError> = await withCheckedContinuation { cont in
            auth.login(email: "user@example.com", password: "pass") { r in
                cont.resume(returning: r)
            }
        }

        if case .failure(.networkError) = result {
            // expected
        } else {
            Issue.record("Expected .networkError, got \(result)")
        }
    }

    // MARK: - Register Tests

    @Test func registerSuccessStoresToken() async {
        let (auth, mock) = makeSUT()
        mock.stubbedPOSTData = TestFixtures.makeAuthResponse(token: "register-jwt-token")

        let result: Result<Void, AuthError> = await withCheckedContinuation { cont in
            auth.register(username: "alice", email: "alice@example.com", password: "secure") { r in
                cont.resume(returning: r)
            }
        }

        if case .failure(let e) = result { Issue.record("Expected success, got \(e)"); return }
        #expect(mock.stubbedToken == "register-jwt-token")
    }

    @Test func registerFailurePropagatesError() async {
        let (auth, mock) = makeSUT()
        mock.stubbedPOSTError = .httpError(statusCode: 409, message: "Email already in use")

        let result: Result<Void, AuthError> = await withCheckedContinuation { cont in
            auth.register(username: "bob", email: "bob@example.com", password: "pass") { r in
                cont.resume(returning: r)
            }
        }

        if case .failure(.registrationFailed) = result {
            // expected
        } else {
            Issue.record("Expected .registrationFailed, got \(result)")
        }
    }

    // MARK: - Logout Tests

    @Test func logoutClearsToken() async {
        let (auth, mock) = makeSUT()
        mock.stubbedToken = "existing-token"

        auth.logout()

        #expect(mock.stubbedToken == nil)
    }

    // MARK: - isLoggedIn Tests

    @Test func isLoggedInReflectsNetworkManagerAuthState() {
        let (auth, mock) = makeSUT()

        mock.stubbedIsAuthenticated = true
        #expect(auth.isLoggedIn == true)

        mock.stubbedIsAuthenticated = false
        #expect(auth.isLoggedIn == false)
    }
}
