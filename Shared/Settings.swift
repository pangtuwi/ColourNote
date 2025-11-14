//
//  Settings.swift
//  FitForm
//
//  Created by Paul Williams on 24/11/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation
import UIKit

let Settings = UserDefaults.standard

extension UserDefaults {

    //IP Address for Efrt Server
    //static let EFRTIP = "206.189.25.97:8080"
    static let EFRTIP = "localhost:8080"
    
    func isRegistered () -> Bool {
        if let _ = string(forKey: "isRegistered"){
            printMQ("user is registered, username is \(userName())")
            return true
        } else {
            printMQ("user : \(userName()) is NOT registered")
            return false
        }
    } //isRegistered
    
    
    func hasDefaultsSet () -> Bool {
        if let _ = string(forKey: "hasDefaultSettings"){
            print("App has Default Settings")
            //n return true
            return false
        } else {
            set (true, forKey: "hasDefaultSettings")
            print("App did not have Default Settngs, now set.")
            return false
        }
    } //hasDefaultsSet

    func clearDefaults () {
        set (false, forKey: "hasDefaultSettings")
    } //clearDefaults
    
    
    func setInitialDefaults () {
        //setUserName(newUserName: "pangtuwi@gmail.com")
        //setUserName(newUserName: "paulnt.williams@gmail.com")
        //setUserName(newUserName: "paulnt.williams@bentley.co.uk")
        //setPassword(newPassword: "pdhn!08Garmin")
        //setPassword(newPassword: "Icntoagp42")
        //setDeviceToken(newDeviceToken: "6242fc0e5a2665c1242a236c11cd20db0bfe2e4714c821b46bda6e6de07f0134")
        setEfrtDays(newEfrtDays: 90)
        setFitnessDisplay(min: 0, max : 100)
        setCyclingFTP(newFTP : 275)
    } //setInitialDefaults

    func setRegistered (registered : Bool) {
        set (registered, forKey: "isRegistered")
    }
    
    func setUserName (newUserName : String) {
        set (newUserName, forKey: "user_name")
    } //setUserName

    func setPassword (newPassword : String) {
        set (newPassword, forKey: "password")
    } //setPassword
    //ToDo : Encrypt (Hash) this.
    
    func setDeviceToken (newDeviceToken : String) {
        let oldDeviceToken = deviceToken()
        if (oldDeviceToken != newDeviceToken) {
            set (newDeviceToken, forKey: "device_token")
            // DataLoader.sharedInstance.sendNewDeviceToken() // Legacy fitness tracking
        }
    } //setDeviceToken
    
    func setEfrtDays (newEfrtDays : Int) {
        set (newEfrtDays, forKey: "efrt_days")
    } //setEfrtDays
    
    func setFitnessDisplay (min : Int, max : Int) {
        set (min, forKey: "fitness_display_min")
        set (max, forKey: "fitness_display_max")
    } //setEfrtDays
    
    
    func setCyclingFTP (newFTP : Int) {
        set (newFTP, forKey: "cycling_ftp")
    } //setEfrtDays
    
    //  Functions to retrieve / set values   - - - - - -
    func userName () -> String {
        return string(forKey: "user_name") ?? ""
    }
    
    func password () -> String {
        return string(forKey : "password") ?? ""
    }
    
    func deviceToken () -> String {
        return string(forKey: "device_token") ?? ""
    }
    
    func efrtDays () -> Int {
        return integer(forKey: "efrt_days")
    }
    
    func fitnessDisplayMin () -> Int {
        return integer(forKey: "fitness_display_min")
    }
    
    func fitnessDisplayMax () -> Int {
        return integer(forKey: "fitness_display_max")
    }
    
    func cyclingFTP () -> Int {
        return integer(forKey: "cycling_ftp")
    }
    

    

    // - - - - -

}
