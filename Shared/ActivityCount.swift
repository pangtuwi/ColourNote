//
//  ActivityCount.swift
//  FitForm
//
//  Created by Paul Williams on 22/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation

class ActivityCount {
    
    var activities : [Activity] = []
    
    var noSwims : Int
    var noRuns : Int
    var noCycles : Int
    var secsSwimming : Int
    var secsRunning : Int
    var secsCycling : Int
    var secsOther : Int
    var TSSTotal : Int
    
    init (dayCount : Int) {
        let now = Int(Date().timeIntervalSince1970)
        let timeStampSince = now - (dayCount*24*60*60)
        activities = ActivityRecords.instance.getActivitiesSince(timeStamp: timeStampSince)
        noRuns = 0
        noSwims = 0
        noCycles = 0
        
        secsCycling = 0
        secsRunning = 0
        secsSwimming = 0
        secsOther = 0
        
        TSSTotal = 0
        
        for activity in activities {
            
            TSSTotal += activity.tss
            
            switch activity.sport {
            case Sport.Running.rawValue, Sport.TreadmillRunning.rawValue, Sport.Hiking.rawValue :
                noRuns += 1
                secsRunning += activity.duration
                
            case Sport.Cycling.rawValue, Sport.IndoorCycling.rawValue, Sport.VirtualCycling.rawValue :
                noCycles += 1
                secsCycling += activity.duration
        
            case Sport.Swimming.rawValue, Sport.LapSwimming.rawValue, Sport.OpenWaterSwimming.rawValue :
                noSwims += 1
                secsSwimming += activity.duration
                
            case Sport.MountainBiking.rawValue :
                noCycles += 1
                secsCycling += activity.duration
                
            default :
                secsOther += activity.duration
            } //switch
        } // for activity
    } // init
    
    func runningTimeString () -> String {
        return (sessionTimeString(timer_time: secsRunning))
    }
    
    func swimmingTimeString () -> String {
        return (sessionTimeString(timer_time: secsSwimming))
    }
    
    func cyclingTimeString () -> String {
        return (sessionTimeString(timer_time: secsCycling))
    }
    
    func totalTimeString () -> String {
        return (sessionTimeString(timer_time: secsOther + secsSwimming + secsRunning + secsCycling))
    }
    
    
    func sessionTimeString (timer_time : Int) -> String {
        var returnString = ""
        if timer_time > 0 {
            let duration: TimeInterval = Double(timer_time)
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .positional
            formatter.allowedUnits = [.hour, .minute, .second ]
            formatter.zeroFormattingBehavior = [ .pad ]
            
            returnString = formatter.string(from: duration)!
        }
        
        return(returnString)
    } //SessionTimeString
    
} //ActivityCount
