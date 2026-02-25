//
//  NoteSyncServiceTests.swift
//  ColourNoteXCTests
//
//  Tests for NoteSyncService download paths using MockNetworkManager.
//

import Testing
import Foundation
@testable import ColourNote

struct NoteSyncServiceTests {

    private func makeSUT() -> (NoteSyncService, MockNetworkManager) {
        let mock = MockNetworkManager()
        let svc = NoteSyncService(networkManager: mock)
        return (svc, mock)
    }

    // MARK: - Download Tests

    @Test func downloadNotesTreats304AsSuccessWithZeroCount() async {
        let (svc, mock) = makeSUT()
        mock.stubbedGETError = .notModified

        let result: Result<Int, NoteSyncError> = await withCheckedContinuation { cont in
            svc.downloadAllNotes { r in cont.resume(returning: r) }
        }

        switch result {
        case .success(let count):
            #expect(count == 0)
        case .failure(let error):
            Issue.record("Expected success(0) for 304, got \(error)")
        }
    }

    @Test func downloadNotesReturnsNetworkErrorOnFailure() async {
        let (svc, mock) = makeSUT()
        mock.stubbedGETError = .networkError(URLError(.notConnectedToInternet))

        let result: Result<Int, NoteSyncError> = await withCheckedContinuation { cont in
            svc.downloadAllNotes { r in cont.resume(returning: r) }
        }

        if case .failure(.networkError) = result {
            // expected
        } else {
            Issue.record("Expected .failure(.networkError), got \(result)")
        }
    }

    @Test func downloadNotesCallsNotesEndpoint() async {
        let (svc, mock) = makeSUT()
        // Return empty array so the service exits quickly
        mock.stubbedGETData = [CloudNote]()

        let _: Result<Int, NoteSyncError> = await withCheckedContinuation { cont in
            svc.downloadAllNotes { r in cont.resume(returning: r) }
        }

        #expect(mock.calledEndpoints.contains(APIConfig.Endpoints.notes))
    }

    @Test func downloadWithSinceParamCallsCorrectEndpoint() async {
        let (svc, mock) = makeSUT()
        mock.stubbedGETData = [CloudNote]()

        let _: Result<Int, NoteSyncError> = await withCheckedContinuation { cont in
            svc.downloadAllNotes(since: 1_700_000_000_000) { r in cont.resume(returning: r) }
        }

        #expect(mock.calledEndpoints.contains(APIConfig.Endpoints.notes))
    }

    // MARK: - Permanent Delete

    @Test func permanentlyDeleteUnmappedNoteSucceeds() async {
        let (svc, _) = makeSUT()
        // Note ID 999999 will never have a cloud mapping
        let result: Result<Void, NoteSyncError> = await withCheckedContinuation { cont in
            svc.permanentlyDeleteCloudNote(localId: 999_999) { r in cont.resume(returning: r) }
        }

        if case .failure(let e) = result {
            Issue.record("Expected success for unmapped note, got \(e)")
        }
    }
}
