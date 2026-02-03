//
//  APIConfig.swift
//  ColourNote
//
//  Cloud Sync API Configuration
//

import Foundation

struct APIConfig {

    // MARK: - Base URL
    static let baseURL = "http://irids.co.uk"

    // MARK: - Endpoints
    struct Endpoints {
        // Authentication
        static let register = "/auth/register"
        static let login = "/auth/login"

        // Categories
        static let categories = "/categories"
        static func category(id: String) -> String { "/categories/\(id)" }

        // Notes
        static let notes = "/notes"
        static func note(id: String) -> String { "/notes/\(id)" }
    }

    // MARK: - Timeouts
    struct Timeouts {
        static let request: TimeInterval = 30.0
        static let resource: TimeInterval = 60.0
    }

    // MARK: - HTTP Headers
    struct Headers {
        static let contentType = "Content-Type"
        static let authorization = "Authorization"
        static let accept = "Accept"
        static let ifMatch = "If-Match"
        static let eTag = "ETag"

        static let applicationJSON = "application/json"
    }

    // MARK: - Keychain Keys
    struct KeychainKeys {
        static let jwtToken = "com.colornote.jwt_token"
        static let userEmail = "com.colornote.user_email"
    }

    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let lastSyncTime = "lastSyncTime"
        static let autoSyncEnabled = "autoSyncEnabled"
        static let syncSchemaVersion = "SyncDatabaseSchemaVersion"
        static let lastCategorySyncTime = "lastCategorySyncTime"
        static let lastNoteSyncTime = "lastNoteSyncTime"
    }

    // MARK: - Helper Methods
    static func fullURL(for endpoint: String) -> URL? {
        return URL(string: baseURL + endpoint)
    }
}
