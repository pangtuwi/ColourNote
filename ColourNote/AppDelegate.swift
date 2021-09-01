//
//  AppDelegate.swift
//  eFit
//
//  Created by Paul Williams on 27/09/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//
// https://github.com/dropbox/SwiftyDropbox#application-plist-file
// https://www.raywenderlich.com/8164-push-notifications-tutorial-getting-started
// https://stackoverflow.com/questions/41811070/show-a-view-on-first-launch-only-swift-3


import UIKit
//import SwiftyDropbox
import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let rootViewController = storyboard.instantiateViewController(withIdentifier: Settings.isRegistered() ? "efrtHomeControllerID" : "loginViewControllerID")
        
        window?.rootViewController = rootViewController
        
        if !Settings.hasDefaultsSet() {
            Settings.setInitialDefaults()
        }
        
        registerForPushNotifications()
        
        // Check if launched from notification
        let notificationOption = launchOptions?[.remoteNotification]
        
        //Handle notifications when sent while app not running or in background
        if let notification = notificationOption as? [String: AnyObject],
            let _ = notification["aps"] as? [String: AnyObject] {
           // NewsItem.makeNewsItem(aps)
            DataLoader.sharedInstance.loadNewActivityList(whenDone: gotList)

            (window?.rootViewController as? UITabBarController)?.selectedIndex = 4 //Training
        } else {
            DataLoader.sharedInstance.downloadMissingEFRT()
        }
        
        //Set small Red circle (Icon badge Number) to Zero
        application.applicationIconBadgeNumber = 0
        
        let navigation = UINavigationBar.appearance()
        
        let navigationFont = UIFont(name: "audiowide-regular", size: 20)
        let navigationLargeFont = UIFont(name: "audiowide-regular", size: 34) //34 is Large Title size by default
        
        navigation.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: navigationFont!]
        
        if #available(iOS 11, *){
            navigation.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: navigationLargeFont!]
        }
        
        return true
    }
    

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) {
                [weak self] granted, error in
                
                print("Permission granted: \(granted)")
                guard granted else { return }
                self?.getNotificationSettings()
        }

    }


    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            //print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
        ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        Settings.setDeviceToken(newDeviceToken: token)
    }
    
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
        //Settings.setDeviceToken(newDeviceToken: "6242fc0e5a2665c1242a236c11cd20db0bfe2e4714c821b46bda6e6de07f0134")
    }
    
    
    //Handle notifications while app running or in background
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler:
        @escaping (UIBackgroundFetchResult) -> Void
        ) {
        guard let _ = userInfo["aps"] as? [String: AnyObject] else {
            completionHandler(.failed)
            return
        }
        //print ("Got notification with \(aps)")
        //NewsItem.makeNewsItem(aps)
        DataLoader.sharedInstance.loadNewActivityList(whenDone: gotList)
    }
    
    
    func gotList (newActivityList : [Int]) -> Void {
        //ToDo: Add message for when Server not available
        if newActivityList.count > 0 {
            //print ("Got Activity List with \(newActivityList.count) activities")
            for newActivityId in newActivityList {
                DataLoader.sharedInstance.getEfrt(whenDone: gotNewActivity, ActivityId: newActivityId)
            }
        }
    } //gotList
    
    
    func gotNewActivity (efrt : Efrt) -> Void {
        //Do nothing for now
    }
    



}

