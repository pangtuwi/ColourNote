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

        // Initialize database synchronously on main thread to avoid race conditions
        // Since database initialization is fast, this provides better startup reliability
        if Settings.isRegistered() {
            print("Initializing database...")
            let startTime = Date()
            _ = NoteRecords.instance
            _ = CategoryRecords.instance
            let elapsed = Date().timeIntervalSince(startTime)
            print("Database initialized in \(elapsed) seconds")
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

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Clear passcode session - require re-entry when app returns
        PasscodeManager.shared.clearSession()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Clear passcode session
        PasscodeManager.shared.clearSession()
    }

}

