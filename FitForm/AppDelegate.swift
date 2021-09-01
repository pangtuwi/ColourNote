//
//  AppDelegate.swift
//  FitForm
//
//  Created by Paul Williams on 06/07/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//
// // Uses Bitbucket  https://bitbucket.org/pangtuwi/efrt/src/

import Cocoa
//import SwiftyDropbox

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
    //    DropboxClientsManager.setupWithAppKeyDesktop("t3rygg2sue2w8yj")
        
        NSAppleEventManager.shared().setEventHandler(self,
                                                     andSelector: #selector(handleGetURLEvent),
                                                     forEventClass: AEEventClass(kInternetEventClass),
                                                     andEventID: AEEventID(kAEGetURL))
     
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    

    
  /*  @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor?, replyEvent: NSAppleEventDescriptor?) {
        if let aeEventDescriptor = event?.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) {
            if let urlStr = aeEventDescriptor.stringValue {
                let url = URL(string: urlStr)!
                if let authResult = DropboxClientsManager.handleRedirectURL(url) {
                    switch authResult {
                    case .success:
                        print("Success! User is logged into Dropbox. \n")
                    case .cancel:
                        print("Authorization flow was manually canceled by user!")
                    case .error(_, let description):
                        print("Error: \(description)")
                    }
                }
                // this brings your application back the foreground on redirect
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    } */


}

