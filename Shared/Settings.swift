//
//  Settings.swift
//  ColourNote
//
//  Created by Paul Williams on 24/11/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation
import UIKit

let Settings = UserDefaults.standard

extension UserDefaults {

    func isRegistered () -> Bool {
        if let _ = string(forKey: "isRegistered"){
            return true
        } else {
            return false
        }
    } //isRegistered


    func hasDefaultsSet () -> Bool {
        if let _ = string(forKey: "hasDefaultSettings"){
            print("App has Default Settings")
            return false
        } else {
            set (true, forKey: "hasDefaultSettings")
            print("App did not have Default Settings, now set.")
            return false
        }
    } //hasDefaultsSet

    func clearDefaults () {
        set (false, forKey: "hasDefaultSettings")
    } //clearDefaults


    func setInitialDefaults () {
        // Set any initial default settings for ColourNote here if needed
    } //setInitialDefaults

    func setRegistered (registered : Bool) {
        set (registered, forKey: "isRegistered")
    }

}
