//
//  LoginViewController.swift
//  eFrt
//
//  Created by Paul Williams on 13/08/2019.
//  Copyright © 2019 Paul Williams. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    var mySender : (Any)? = nil
    let spinner = SpinnerViewController()
    
    @IBOutlet weak var UITF_username : UITextField!
    @IBOutlet weak var UITF_password : UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func signInButtonTapped(_ sender: Any) {
        //Get Values from Text Fields
        let username = UITF_username.text
        let password = UITF_password.text
        if (username?.count ?? 0 > 0) && (password?.count ?? 0 > 0) {
            Settings.setUserName(newUserName: username ?? "")
            Settings.setPassword(newPassword: password ?? "")
        
            // add the spinner view controller
            addChild(spinner)
            spinner.view.frame = view.frame
            view.addSubview(spinner.view)
            spinner.didMove(toParent: self)
            
            mySender = sender
            DataLoader.sharedInstance.userExists(whenDone: userExists)
        } else {
            let alert = UIAlertController(title: "Username or Password not entered", message: "You need to enter an email address and passowrd to continuer", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                
            }
            alert.addAction(okAction)
         
            self.present(alert, animated: true, completion: nil)
        }
    } //Signin button tapped
    
    
    func userExists (exists : Bool, message : String) {
        printMQ("userExists for \(Settings.userName()) got \(exists) with message \(message)")
        
        DispatchQueue.main.async {
            //Stop the spinner
            self.spinner.willMove(toParent: nil)
            self.spinner.view.removeFromSuperview()
            self.spinner.removeFromParent()
        
        
            if exists {
                // User exists, enable in settinngs and transition to main UI
                Settings.setRegistered(registered: true)
                DataLoader.sharedInstance.downloadMissingEFRT()
                self.performSegue(withIdentifier: "signedInSegue", sender: self.mySender)
            
            } else {
                //User not found
                let alert = UIAlertController(title: "User Not Found", message: "\(Settings.userName()) was not found in the EFRT database - do you want to add this user", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                    DataLoader.sharedInstance.addUser()
                    Settings.setRegistered(registered: true)
                    DataLoader.sharedInstance.downloadMissingEFRT()
                    self.performSegue(withIdentifier: "signedInSegue", sender: self.mySender)
                }
                alert.addAction(okAction)
                let cancelAction = UIAlertAction(title: "No", style: .cancel) { _ in
                // Handle your cancel action
                }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    } //userExists

}
