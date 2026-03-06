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
}
