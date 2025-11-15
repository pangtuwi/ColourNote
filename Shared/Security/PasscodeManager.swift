//
//  PasscodeManager.swift
//  ColourNote
//
//  Created for passcode protection functionality
//

import Foundation
import CryptoKit

class PasscodeManager {

    static let shared = PasscodeManager()

    private let passcodeKey = "GlobalPasscodeHash"
    private var unlockedCategoryIDs: Set<Int> = []

    private init() {}

    // MARK: - Passcode Management

    /// Check if a global passcode has been set
    var isPasscodeSet: Bool {
        return UserDefaults.standard.string(forKey: passcodeKey) != nil
    }

    /// Set a new global passcode (hashed with SHA-256)
    func setPasscode(_ passcode: String) -> Bool {
        guard passcode.count == 4, passcode.allSatisfy({ $0.isNumber }) else {
            return false
        }

        let hash = hashPasscode(passcode)
        UserDefaults.standard.set(hash, forKey: passcodeKey)
        UserDefaults.standard.synchronize()
        return true
    }

    /// Validate a passcode against the stored hash
    func validatePasscode(_ passcode: String) -> Bool {
        guard let storedHash = UserDefaults.standard.string(forKey: passcodeKey) else {
            return false
        }

        let inputHash = hashPasscode(passcode)
        return inputHash == storedHash
    }

    /// Remove the global passcode
    func removePasscode() {
        UserDefaults.standard.removeObject(forKey: passcodeKey)
        UserDefaults.standard.synchronize()
        clearSession()
    }

    /// Change the passcode (requires old passcode validation)
    func changePasscode(oldPasscode: String, newPasscode: String) -> Bool {
        guard validatePasscode(oldPasscode) else {
            return false
        }

        return setPasscode(newPasscode)
    }

    // MARK: - Session Management

    /// Check if a category is currently unlocked
    func isCategoryUnlocked(_ categoryId: Int) -> Bool {
        return unlockedCategoryIDs.contains(categoryId)
    }

    /// Unlock a category for this session
    func unlockCategory(_ categoryId: Int) {
        unlockedCategoryIDs.insert(categoryId)
    }

    /// Lock a category
    func lockCategory(_ categoryId: Int) {
        unlockedCategoryIDs.remove(categoryId)
    }

    /// Clear all unlocked categories (call on app background/terminate)
    func clearSession() {
        unlockedCategoryIDs.removeAll()
    }

    /// Get all currently unlocked category IDs
    func getUnlockedCategories() -> Set<Int> {
        return unlockedCategoryIDs
    }

    // MARK: - Private Helpers

    /// Hash a passcode using SHA-256
    private func hashPasscode(_ passcode: String) -> String {
        let data = Data(passcode.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
