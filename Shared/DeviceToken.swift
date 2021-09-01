//
//  DeviceID.swift
//  FitForm
//
//  Created by Paul Williams on 29/12/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation

struct DeviceToken : Codable {
    var username : String
    var devicetoken : String
    
    init (){
        username = Settings.userName()
        devicetoken = Settings.deviceToken()
    }
}
