//
//  Helpers.swift
//  FitForm
//
//  Created by Paul Williams on 15/09/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation

func timeString (unixTime : Int) -> String {
    var returnString = ""
    if unixTime > 0 {
        let duration: TimeInterval = Double(unixTime)
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second ]
        formatter.zeroFormattingBehavior = [ .pad ]
        
        returnString = formatter.string(from: duration)!
    }
    
    return(returnString)
} //timeDateString


func timeDateString (unixTime : Int) -> String {
    if unixTime == 0 {
        return ""
    } else {
        let date = Date(timeIntervalSince1970: Double(unixTime))
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "MMM dd YYYY hh:mm a"
        return dayTimePeriodFormatter.string(from: date)
    }
} //timeDateString
