//
//  RunPoint.swift
//  FitForm
//
//  Created by Paul Williams on 27/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation

struct RunTrackPoint {
    var startTime : Int
    var timeStamp : Int
    
    var heartRate : Double
    var distance : Double
    var altitude : Double
    var speed : Double
    var cadence : Double
    
    var latitude : Double
    var longitude : Double
    
    mutating func setTimeStamp (newTimeStamp : Int) {
     timeStamp = newTimeStamp
     } 
    
}
