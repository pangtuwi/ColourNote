//
//  URLs.swift
//  FitForm
//
//  Created by Paul Williams on 02/04/2019.
//  Copyright © 2019 Paul Williams. All rights reserved.
//

import Foundation

let URLs = EfrtURLs()

class EfrtURLs {
    
    func eFrtServerDeviceTokenURL () -> URL {
        let urlString = "http://\(UserDefaults.EFRTIP)/v1/users/" + Settings.userName() + "/devicetoken"
        return  URL(string: urlString)!
    }
    
    func eFrtServerUpdatePasswordURL () -> URL {
        let urlString = "http://\(UserDefaults.EFRTIP)/v1/users/" + Settings.userName() + "/updatepassword"
        return  URL(string: urlString)!
    }
    
    func eFrtServerAddUserURL () -> URL {
        let urlString = "http://\(UserDefaults.EFRTIP)/v1/users/" + Settings.userName() + "/adduser"
        return  URL(string: urlString)!
    }

    func eFrtServerListURL () -> URL {
        //Implementing URLSession
        let urlString = "http://\(UserDefaults.EFRTIP)/v1/users/" + Settings.userName() + "/activities2"
        return  URL(string: urlString)!
    } //efRtServerURL


    func eFrtServerTCXURL (GarminActivityID : String) -> URL {
        let urlString = "http://\(UserDefaults.EFRTIP)/v1/users/" + Settings.userName() + "/activities/" + String(GarminActivityID) + "/tcx"
        return  URL(string: urlString)!
    }

    func eFrtServerJSONURL (GarminActivityID : String) -> URL {
        let urlString = "http://\(UserDefaults.EFRTIP)/v1/users/" + Settings.userName() + "/activities/" + String(GarminActivityID) + "/json"
        return  URL(string: urlString)!
    }

    func eFrtServerActivityURL (GarminActivityID : String) -> URL {
        let urlString = "http://\(UserDefaults.EFRTIP)/v1/users/" + Settings.userName() + "/activities/" + String(GarminActivityID) + "/activity"
        return  URL(string: urlString)!
    }

    func eFrtServerEfrtURL (GarminActivityID : Int) -> URL {
        let urlString = "http://\(UserDefaults.EFRTIP)/v1/users/" + Settings.userName() + "/activities/" + String(GarminActivityID) + "/efrt"
        return  URL(string: urlString)!
    }

    func eFrtServerTrackPointsURL (GarminActivityID : Int, freq : Int) -> URL {
        let urlStringPart2 = "/activities/" + String(GarminActivityID) + "/trackpoints?freq=" + String(freq)
        let urlString = "http://\(UserDefaults.EFRTIP)/v1/users/" + Settings.userName() + urlStringPart2
        return  URL(string: urlString)!
    }

    func eFrtServerSyncURL () -> URL {
        let urlString = "http://\(UserDefaults.EFRTIP)/v1/users/" + Settings.userName() + "/sync"
        return  URL(string: urlString)!
    } //efRtServerURL

    func eFrtServerHasUserURL () -> URL {
        let urlString = "http://\(UserDefaults.EFRTIP)/v1/users/" + Settings.userName() + "/hasuser"
        return  URL(string: urlString)!
    } //efRtServerURL
    
    func eFrtServerTestConnectionURL () -> URL {
        let urlString = "http://\(UserDefaults.EFRTIP)/v1/users/" + Settings.userName() + "/testconnection"
        return  URL(string: urlString)!
    } //efRtServerURL
}
