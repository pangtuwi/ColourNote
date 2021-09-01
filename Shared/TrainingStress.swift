//
//  TrainingStress.swift
//  FitForm
//
//  Created by Paul Williams on 20/09/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation

class TrainingStress {
    
    var numDays : Int
    var numWeeks : Int
    let trainingLambda = 1.0 / 42   //42 day EWMA filter
    let fatigueLambda = 1.0 / 7     //7 day EWMA Filter
    
    var activities : [Activity] = []
    var dayTSS : [Int]
    var weekTSS : [Int]
    var fitnessEWMA : [Double] = []
    var fatigueEWMA : [Double] = []
    var avgTSS : Double = 0
    
    init() {
        activities = ActivityRecords.instance.getActivities()
        //Settings.setEfrtDays(newEfrtDays: 90)
        if activities.count > Settings.efrtDays() {
           numDays = Settings.efrtDays()
        } else {
            numDays = activities.count
        }
        numWeeks = (numDays / 7) + 1
        dayTSS = Array (repeating: 0, count: numDays)
        weekTSS = Array (repeating: 0, count : numWeeks)
        fillDayWeekTSS()
        fitnessEWMA = calculateEWMA(EWMALambda: trainingLambda)
        fatigueEWMA = calculateEWMA(EWMALambda: fatigueLambda)
    } //init
    
    
    func fillDayWeekTSS() {
        //Fills array of TSS from activities Array (which has been loaded from Database
        var totalTSS = 0
        //let now = Int(Date().timeIntervalSince1970)
        
        for activity in activities {
            if activity.ignore == false {
                var thisTSS = activity.tss
                if (thisTSS == -1) {thisTSS = 0}
                let thisTimeStamp = activity.startTime
                
                //DayTSS
                //let thisDaysAgo = Int((now - thisTimeStamp) / (24 * 60 * 60))  //convert to days
                let thisDaysAgo = Date().getDaysAgo(unixTime: Double(thisTimeStamp))
                if thisDaysAgo < numDays {
                    dayTSS[thisDaysAgo] += thisTSS
                    totalTSS += thisTSS
                }
                
                //Week TSS
                let weekStart = Date().getWeekStart()
                let thisWeeksAgo = weekStart.getWeeksAgo(unixTime: Double(thisTimeStamp))
                if thisWeeksAgo < numWeeks {
                    weekTSS[thisWeeksAgo] += thisTSS
                }
            }
        }
        dayTSS.reverse()
        weekTSS.reverse()
        avgTSS = Double(totalTSS) / Double(numDays)
    } //fillDayTSS
    
    
    
    func calculateEWMA (EWMALambda : Double) -> [Double] {
        var EWMAArray : [Double] = []
        var lastEWMA = avgTSS
        for point in dayTSS {
            let newEWMA = (lastEWMA * (1 - EWMALambda)) + (Double(point) * EWMALambda)
            EWMAArray.append(newEWMA)
            lastEWMA = newEWMA
        }
        return EWMAArray
    } // calculateEWMA
    

}
