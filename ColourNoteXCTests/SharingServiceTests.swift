//
//  SharingServiceTests.swift
//  ColourNoteXCTests
//
//  Tests for SharingService API calls using MockNetworkManager.
//

import Testing
import Foundation
@testable import ColourNote

struct SharingServiceTests {

    private func makeSUT() -> (SharingService, MockNetworkManager) {
        let mock = MockNetworkManager()
        let svc = SharingService(networkManager: mock)
        return (svc, mock)
    }

    // MARK: - createShare

    @Test func createShareSuccessReturnsShareURL() async {
        let (svc, mock) = makeSUT()
        mock.stubbedPOSTData = ShareNoteResponse(
            shareUrl: "https://irids.co.uk/share/abc123",
            token: "abc123"
        )

        let result: Result<String, Error> = await withCheckedContinuation { cont in
            svc.createShare(noteUUID: "note-uuid-1", recipientEmail: "bob@example.com") { r in
                cont.resume(returning: r)
            }
        }

        switch result {
        case .success(let url):
            #expect(url == "https://irids.co.uk/share/abc123")
        case .failure(let error):
            Issue.record("Expected success, got \(error)")
        }
    }

    @Test func createShareNetworkErrorPropagatesFailure() async {
        let (svc, mock) = makeSUT()
        mock.stubbedPOSTError = .networkError(URLError(.notConnectedToInternet))

        let result: Result<String, Error> = await withCheckedContinuation { cont in
            svc.createShare(noteUUID: "note-uuid-2", recipientEmail: "alice@example.com") { r in
                cont.resume(returning: r)
            }
        }

        if case .failure = result {
            // expected
        } else {
            Issue.record("Expected failure, got \(result)")
        }
    }

    @Test func createShareCallsCorrectEndpoint() async {
        let (svc, mock) = makeSUT()
        mock.stubbedPOSTData = ShareNoteResponse(
            shareUrl: "https://irids.co.uk/share/tok",
            token: "tok"
        )

        let _: Result<String, Error> = await withCheckedContinuation { cont in
            svc.createShare(noteUUID: "uuid-abc", recipientEmail: "test@example.com") { r in
                cont.resume(returning: r)
            }
        }

        #expect(mock.calledEndpoints.contains("/notes/uuid-abc/share"))
    }

    @Test func createShareSendsRecipientEmailInBody() async {
        let (svc, mock) = makeSUT()
        mock.stubbedPOSTData = ShareNoteResponse(
            shareUrl: "https://irids.co.uk/share/tok",
            token: "tok"
        )

        let _: Result<String, Error> = await withCheckedContinuation { cont in
            svc.createShare(noteUUID: "uuid-xyz", recipientEmail: "carol@example.com") { r in
                cont.resume(returning: r)
            }
        }

        let body = mock.lastBody as? ShareNoteRequest
        #expect(body?.recipientEmail == "carol@example.com")
    }

    @Test func createShareHttpErrorPropagatesFailure() async {
        let (svc, mock) = makeSUT()
        mock.stubbedPOSTError = .httpError(statusCode: 404, message: "Note not found")

        let result: Result<String, Error> = await withCheckedContinuation { cont in
            svc.createShare(noteUUID: "uuid-missing", recipientEmail: "nobody@example.com") { r in
                cont.resume(returning: r)
            }
        }

        if case .failure = result {
            // expected
        } else {
            Issue.record("Expected failure for 404 server error, got \(result)")
        }
    }
}
