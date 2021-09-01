//
//  Activity.swift
//  FitForm
//
//  Created by Paul Williams on 12/09/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation

class Activity {
    
    // Simple Form of Activity Data For Training Stats
    
    var activityId : Int
    var activityName : String
    let startTime : Int
    var filename : String
    var sport : Int
    var duration : Int
    var distance : Int
    var tss : Int
    var ignore : Bool
    
    init() {
        activityId = 0
        activityName = ""
        startTime = 0
        filename = ""
        sport = -1
        duration = 0
        distance = 0
        tss = 0
        ignore = false
    }
    
    init(activityId : Int, activityName : String, startTime: Int, filename: String, sport: Int, duration: Int, distance : Int, tss : Int, ignore : Bool) {
        self.activityId = activityId
        self.activityName = activityName
        self.startTime = startTime
        self.filename = filename
        self.sport = sport
        self.duration = duration
        self.distance = distance
        self.tss = tss
        self.ignore = ignore
    }
    
    
    func agoString () -> String {
        if (startTime == 0) {
            return ("")
        }
        let now = Int(Date().timeIntervalSince1970)
        let midnight = now / (24*60*60) * (24*60*60)
        let midnightyesterday = midnight - (24*60*60)
        let thisTimeStamp = startTime
        let thisDaysAgo = Int((midnight - thisTimeStamp) / (24 * 60 * 60) + 1 )  //convert to days
        if thisTimeStamp > midnight {return "Today"}
        else if thisTimeStamp > midnightyesterday {return "Yesterday"}
        else {return "\(thisDaysAgo) days ago"}
    } //agoString
    
    
    func sportString () -> String {
        return Sport(rawValue: sport)?.description() ?? "Unknown Sport"
    } //sportString
    
    
    func shouldDrawMap () -> Bool {
        return Sport(rawValue: sport)?.shouldMap() ?? true
    }
    
    func hasHeartRate () -> Bool {
        let isSwim = Sport(rawValue: sport)?.isSwim() ?? false
        return !isSwim
    }
    
    func isSwim () -> Bool {
        let isSwim = Sport(rawValue: sport)?.isSwim() ?? false
        return isSwim
    }
    
}

