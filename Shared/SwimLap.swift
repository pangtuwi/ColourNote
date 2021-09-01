//
//  SwimLapRecord.swift
//  FitForm
//
//  Created by Paul Williams on 26/08/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation

struct SwimLap {
    var startTime : Int
    var timeStamp : Int
    let lapDistance : Double
    let lapTime : Double
    
  /*  mutating func setTimeStamp (newTimeStamp : Int) {
        timeStamp = newTimeStamp
    } */
    
    func secs100m () -> Double {
        //time per 100m
        return lapTime / lapDistance * 100
    }  // func secs100m
}
