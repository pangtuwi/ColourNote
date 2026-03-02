//
//  AppDelegate.swift
//  ColourNote
//
//  Created by Paul Williams on 27/09/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//


import UIKit
import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("UI_TESTING_FRESH_INSTALL") {
            UserDefaults.standard.removeObject(forKey: "isRegistered")
            // Clear auth state so the sync engine cannot fire during tests.
            // Without this, a stale JWT token in the Keychain causes a 60-second
            // network timeout that prevents XCUITest from detecting the navigation bar.
            AuthManager.shared.logout()
            UserDefaults.standard.removeObject(forKey: "autoSyncEnabled")
            // Clear migration version keys so NoteRecords/CategoryRecords re-run every
            // migration on the blank DB that createBlankDatabase() creates.  Without
            // this, a saved version of "10" / "3" from a prior run causes the migration
            // check to short-circuit, leaving the bare-bones schema in place, and
            // CategoryRecords then crashes querying the missing `uuid` column.
            UserDefaults.standard.removeObject(forKey: "DatabaseSchemaVersion")
            UserDefaults.standard.removeObject(forKey: "CategoryDatabaseSchemaVersion")
            UserDefaults.standard.removeObject(forKey: APIConfig.UserDefaultsKeys.lastNoteSyncTime)
            UserDefaults.standard.removeObject(forKey: APIConfig.UserDefaultsKeys.lastCategorySyncTime)
            if let docs = FileManager.default.urls(for: .documentDirectory,
                                                    in: .userDomainMask).first {
                try? FileManager.default.removeItem(
                    at: docs.appendingPathComponent("colornote.db"))
            }
        }
        #endif

        // Initialize database synchronously on main thread to avoid race conditions
        // Since database initialization is fast, this provides better startup reliability
        if Settings.isRegistered() {
            print("Initializing database...")
            let startTime = Date()
            _ = NoteRecords.instance
            _ = CategoryRecords.instance
            let elapsed = Date().timeIntervalSince(startTime)
            print("Database initialized in \(elapsed) seconds")

            // Initialize sync mapping table
            _ = SyncMapping.shared
        }

        // Ensure window is created
        window = UIWindow(frame: UIScreen.main.bounds)

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let rootViewController = storyboard.instantiateViewController(withIdentifier:
            Settings.isRegistered() ? "ColorNoteHomeID" : "loginViewControllerID")
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()

        if !Settings.hasDefaultsSet() {
            Settings.setInitialDefaults()
        }

        let navigation = UINavigationBar.appearance()

        let navigationFont = UIFont(name: "helveticaneue-thin", size: 20)
        let navigationLargeFont = UIFont(name: "helveticaneue-thin", size: 24) //34 is Large Title size by default

        navigation.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: navigationFont!]

        if #available(iOS 11, *){
            navigation.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: navigationLargeFont!]
        }

        // Trigger auto-sync on app launch if enabled
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            SyncEngine.shared.syncIfNeeded()
        }

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Trigger auto-sync when app comes back to foreground
        SyncEngine.shared.syncIfNeeded()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Clear passcode session - require re-entry when app returns
        PasscodeManager.shared.clearSession()

        // Trigger sync when going to background (if enabled and quick enough)
        if SyncEngine.shared.isAutoSyncEnabled && AuthManager.shared.isLoggedIn {
            // Request background time for sync
            var backgroundTask: UIBackgroundTaskIdentifier = .invalid
            backgroundTask = application.beginBackgroundTask {
                application.endBackgroundTask(backgroundTask)
                backgroundTask = .invalid
            }

            SyncEngine.shared.uploadLocalChanges { _ in
                application.endBackgroundTask(backgroundTask)
                backgroundTask = .invalid
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Clear passcode session
        PasscodeManager.shared.clearSession()
    }

}

