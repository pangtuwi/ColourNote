//
//  CycleTrackPoint.swift
//  FitForm
//
//  Created by Paul Williams on 08/08/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation

struct CycleTrackPoint {
    var activityId : Int
    var timeStamp : Int
    
    var heartRate : Double
    var distance : Double
    var altitude : Double
    var speed : Double
    var power : Double

    var latitude : Double
    var longitude : Double
    
    mutating func setTimeStamp (newTimeStamp : Int) {
        timeStamp = newTimeStamp
    } 
}


