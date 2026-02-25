//
//  CategorySyncServiceTests.swift
//  ColourNoteXCTests
//
//  Tests for CategorySyncService download paths using MockNetworkManager.
//

import Testing
import Foundation
@testable import ColourNote

struct CategorySyncServiceTests {

    private func makeSUT() -> (CategorySyncService, MockNetworkManager) {
        let mock = MockNetworkManager()
        let svc = CategorySyncService(networkManager: mock)
        return (svc, mock)
    }

    // MARK: - Download Tests

    @Test func downloadCategoriesTreats304AsSuccess() async {
        let (svc, mock) = makeSUT()
        mock.stubbedGETError = .notModified

        let result: Result<Int, CategorySyncError> = await withCheckedContinuation { cont in
            svc.downloadAllCategories { r in cont.resume(returning: r) }
        }

        switch result {
        case .success(let count):
            #expect(count == 0)
        case .failure(let error):
            Issue.record("Expected success(0) for 304, got \(error)")
        }
    }

    @Test func downloadCategoriesReturnsNetworkError() async {
        let (svc, mock) = makeSUT()
        mock.stubbedGETError = .networkError(URLError(.timedOut))

        let result: Result<Int, CategorySyncError> = await withCheckedContinuation { cont in
            svc.downloadAllCategories { r in cont.resume(returning: r) }
        }

        if case .failure(.networkError) = result {
            // expected
        } else {
            Issue.record("Expected .failure(.networkError), got \(result)")
        }
    }

    @Test func downloadCategoriesCallsCorrectEndpoint() async {
        let (svc, mock) = makeSUT()
        mock.stubbedGETData = [CloudCategory]()

        let _: Result<Int, CategorySyncError> = await withCheckedContinuation { cont in
            svc.downloadAllCategories { r in cont.resume(returning: r) }
        }

        #expect(mock.calledEndpoints.contains(APIConfig.Endpoints.categories))
    }

    // MARK: - Mark for Upload

    @Test func markForUploadIsNoOpWithoutMapping() {
        let (svc, _) = makeSUT()
        // Category ID 9999 has no sync mapping — must not crash
        svc.markForUpload(categoryId: 9999)
        // If we reach here, the method handled the missing mapping gracefully
    }
}
