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

        // Pre-initialize database on background thread to speed up launch
        if Settings.isRegistered() {
            DispatchQueue.global(qos: .userInitiated).async {
                // This will initialize NoteRecords and CategoryRecords singletons and run migrations in background
                _ = NoteRecords.instance
                _ = CategoryRecords.instance
                print("Database pre-initialized in background")
            }
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let rootViewController = storyboard.instantiateViewController(withIdentifier:
            Settings.isRegistered() ? "ColorNoteHomeID" : "loginViewControllerID")
        window?.rootViewController = rootViewController

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

