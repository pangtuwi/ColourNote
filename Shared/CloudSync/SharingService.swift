//
//  SharingService.swift
//  ColourNote
//
//  Manages note sharing API calls
//

import Foundation

class SharingService {

    // MARK: - Singleton
    static let shared = SharingService()

    // MARK: - Properties
    private let networkManager: NetworkManaging

    // MARK: - Initialization
    private convenience init() { self.init(networkManager: NetworkManager.shared) }
    internal init(networkManager: NetworkManaging) { self.networkManager = networkManager }

    // MARK: - Share Methods

    /// POST /notes/{uuid}/share — creates a share link and returns the share URL
    func createShare(noteUUID: String, recipientEmail: String,
                     completion: @escaping (Result<String, Error>) -> Void) {
        let body = ShareNoteRequest(recipientEmail: recipientEmail)
        let endpoint = "\(APIConfig.Endpoints.notes)/\(noteUUID)/share"
        networkManager.post(endpoint: endpoint, body: body, requiresAuth: true)
            { (result: Result<ShareNoteResponse, NetworkError>) in
            switch result {
            case .success(let response):
                completion(.success(response.shareUrl))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Device Token Registration

    func registerDeviceToken(_ deviceToken: Data,
                              completion: @escaping (Result<Void, Error>) -> Void) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        let body = DeviceTokenRequest(token: hex)
        networkManager.requestNoResponse(
            endpoint: APIConfig.Endpoints.registerDeviceToken,
            method: .POST, body: body, requiresAuth: true
        ) { result in
            completion(result.mapError { $0 as Error })
        }
    }

    // MARK: - Inbox

    func fetchInbox(completion: @escaping (Result<InboxResponse, Error>) -> Void) {
        networkManager.get(
            endpoint: APIConfig.Endpoints.sharesInbox,
            requiresAuth: true
        ) { (result: Result<InboxResponse, NetworkError>) in
            completion(result.mapError { $0 as Error })
        }
    }

    // MARK: - Accept / Decline

    func acceptShare(token: String,
                      completion: @escaping (Result<AcceptShareResponse, Error>) -> Void) {
        networkManager.post(
            endpoint: APIConfig.Endpoints.shareAccept(token: token),
            body: EmptyBody(), requiresAuth: true
        ) { (result: Result<AcceptShareResponse, NetworkError>) in
            completion(result.mapError { $0 as Error })
        }
    }

    func declineShare(token: String,
                       completion: @escaping (Result<Void, Error>) -> Void) {
        networkManager.requestNoResponse(
            endpoint: APIConfig.Endpoints.shareDecline(token: token),
            method: .POST, body: EmptyBody(), requiresAuth: true
        ) { result in
            completion(result.mapError { $0 as Error })
        }
    }
}
