//
//  SettingsViewController.swift
//  eFit
//
//  Created by Paul Williams on 05/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import UIKit
//import SwiftyDropbox

class SettingsViewController: UITableViewController {
    
    @IBOutlet weak var username : UITextField!
    @IBOutlet weak var password : UITextField!
    @IBOutlet weak var efrtdays : UITextField!
    @IBOutlet weak var fitnessDisplayMin : UITextField!
    @IBOutlet weak var fitnessDisplayMax : UITextField!
    @IBOutlet weak var cyclingFTP : UITextField!
    
    var oldEfrtDays = 90
    var oldFitnessDisplayMin = 0
    var oldFitnessDisplayMax = 100
    var oldCyclingFTP = 200
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        username.text = Settings.userName()
        password.text = Settings.password()
        efrtdays.text = "\(Settings.efrtDays())"
        fitnessDisplayMin.text = "\(Settings.fitnessDisplayMin())"
        fitnessDisplayMax.text = "\(Settings.fitnessDisplayMax())"
        cyclingFTP.text = "\(Settings.cyclingFTP())"
        oldEfrtDays = Settings.efrtDays()
        oldCyclingFTP = Settings.cyclingFTP()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if (username.text != Settings.userName()) || (password.text != Settings.password()) {
            Settings.setUserName(newUserName: username.text ?? "")
            Settings.setPassword(newPassword: password.text ?? "")
        }
        
        let newEfrtDays = Int(efrtdays.text ?? "90")
        if (newEfrtDays != oldEfrtDays) {
            Settings.setEfrtDays(newEfrtDays: newEfrtDays ?? 90)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: DataLoaderNotification.contentUpdated, object: nil)
            }
        }
        
        let newFitnessDisplayMin = Int(fitnessDisplayMin.text ?? "0")
        let newFitnessDisplayMax = Int(fitnessDisplayMax.text ?? "100")
        if ((newFitnessDisplayMin != oldFitnessDisplayMin) || (newFitnessDisplayMax != oldFitnessDisplayMax)) {
           Settings.setFitnessDisplay(min: newFitnessDisplayMin ?? 0, max: newFitnessDisplayMax ?? 100)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: DataLoaderNotification.contentUpdated, object: nil)
            }
        }
        
        let newCyclingFTP = Int(cyclingFTP.text ?? "200")
        if (newCyclingFTP != oldCyclingFTP) {
            Settings.setCyclingFTP(newFTP: newCyclingFTP ?? 200)
        }
        
    }
    
    @IBAction func clearUserDataPressed(_ sender: Any) {
        ActivityRecords.instance.deleteAllActivities()
        NotificationCenter.default.post(name: DataLoaderNotification.contentUpdated, object: nil)
    }  //clearUserDataPressed
    
    
    @IBAction func testConnectionPressed(_ sender: Any) {
        if (username.text != Settings.userName()) || (password.text != Settings.password()) {
            Settings.setUserName(newUserName: username.text ?? "")
            Settings.setPassword(newPassword: password.text ?? "")
        }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else {
                return
            }
            DataLoader.sharedInstance.testConnection2(whenDone: self.gotConnectionResponse)
        }
    }  //testConnectionPressed
    
    
    func gotConnectionResponse (response : Bool, msg : String) -> Void {
        let userNotFoundString = "User not found in EfrtServer Database"
        let passwordDoesnotMatchString = "Password does not match"
        if ((response == false) && (msg == userNotFoundString)) {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "User Not Found", message: "The username \(Settings.userName()) was not found in the EFRT database - do you want to add this user", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                    DataLoader.sharedInstance.addUser()
                }
                alert.addAction(okAction)
                let cancelAction = UIAlertAction(title: "No", style: .cancel) { _ in
                    // Handle your cancel action
                }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }
        } else if ((response == false) && (msg == passwordDoesnotMatchString)) {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Password Does Not Match", message: "The password for username \(Settings.userName()) did not match the one stored in our database - do you want to update it", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                    DataLoader.sharedInstance.updatePassword()
                }
                alert.addAction(okAction)
                let cancelAction = UIAlertAction(title: "No", style: .cancel) { _ in
                    // Handle your cancel action
                }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }
        } else {
        
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Garmin Connection Test", message: msg, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                    // Handle your ok action
                }
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
        
    } //gotConnectionResponse
    
    @IBAction func notifyThisDevicePressed(_ sender: Any) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else {
                return
            }
            DataLoader.sharedInstance.sendNewDeviceToken();
            
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Registering Device", message: "This device is now registered to receive messages from the EFRT server", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                    // Handle your ok action
                }
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }  //notifyThisDevicePressed
    
}
