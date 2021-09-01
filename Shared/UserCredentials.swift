//
//  UserCredentials.swift
//  FitForm
//
//  Created by Paul Williams on 21/07/2019.
//  Copyright © 2019 Paul Williams. All rights reserved.
//

import Foundation

struct UserCredentials : Codable {
    var username : String
    var password : String
    var devicetoken : String
    
    init (){
        username = Settings.userName()
        password = Settings.password()
        devicetoken = Settings.deviceToken()
    }
}
