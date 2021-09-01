//
//  ActivityListing.swift
//  FitForm
//
//  Created by Paul Williams on 19/12/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation

struct ActivityListing : Codable {
    let activityId : Int
    let activityName : String?
    let startTimeGMT : String
    let duration : Double
    let distance : Double
    let activityType : GActivityType
    
    func startTime() -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" //Your date format
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT+0:00") //Current time zone
        //according to date format your date string
        guard let date = dateFormatter.date(from: startTimeGMT) else {
            fatalError()
        }
        
        return Int(date.timeIntervalSince1970)
    }
}

struct GActivityType : Codable {
    let typeId : Int
}


