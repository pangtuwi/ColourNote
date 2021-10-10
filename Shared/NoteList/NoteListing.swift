//
//  NoteListing.swift
//  FitForm
//
//  Created by Paul Williams on 03/10/2021.
//  Copyright © 2021 Paul Williams. All rights reserved.
//

import Foundation

struct NoteListing : Codable {
    let noteId : Int
    let noteName : String?
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


