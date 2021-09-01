//
//  Zones.swift
//  FitForm
//
//  Created by Paul Williams on 08/08/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//


//https://www.trainingpeaks.com/blog/estimating-training-stress-score-tss/

import Foundation

struct Zones {
    
    var hrZones = [Zone]()
    var hrTSSZones = [Zone]()
    var swimZones = [Zone]()
    var hrHistogramZones = [Zone]()
    
    init(){
        //Strava based Zones
        let hrzone1 = Zone(name: "Warmup", minValue : 0, maxValue: 109, TSSVal : 0)
        let hrzone2 = Zone(name: "Endurance", minValue : 110, maxValue: 136, TSSVal : 0)
        let hrzone3 = Zone(name: "Tempo", minValue : 137, maxValue: 151, TSSVal : 0)
        let hrzone4 = Zone(name: "Threshold", minValue : 151, maxValue: 164, TSSVal : 0)
        let hrzone5 = Zone(name: "Anaerobic", minValue : 165, maxValue: 255, TSSVal : 0)
        hrZones.append(hrzone1)
        hrZones.append(hrzone2)
        hrZones.append(hrzone3)
        hrZones.append(hrzone4)
        hrZones.append(hrzone5)
        
        //TrainingPeaks Extended Zones
        let hrTSSZone1a = Zone(name: "1 Low Recovery", minValue : 0, maxValue: 100, TSSVal : 20)
        let hrTSSZone1b = Zone(name: "1B Low Recovery", minValue : 101, maxValue: 111, TSSVal : 30)
        let hrTSSZone1c = Zone(name: "1C High Recovery", minValue : 112, maxValue: 122, TSSVal : 40)
        let hrTSSZone2a = Zone(name: "2 Low Aerobic", minValue : 123, maxValue: 129, TSSVal : 50)
        let hrTSSZone2b = Zone(name: "2 High Aerobic", minValue : 130, maxValue: 135, TSSVal : 60)
        let hrTSSZone3 = Zone(name: "3 Tempo", minValue : 136, maxValue: 141, TSSVal : 70)
        let hrTSSZone4 = Zone(name: "4 Sub Threshold", minValue : 142, maxValue: 151, TSSVal : 80)
        let hrTSSZone5a = Zone(name: "5A Super Threshold", minValue : 152, maxValue: 155, TSSVal : 100)
        let hrTSSZone5b = Zone(name: "5B Aerobic Capacity", minValue : 156, maxValue: 161, TSSVal : 120)
        let hrTSSZone5c = Zone(name: "5C Anaerobic", minValue : 162, maxValue: 255, TSSVal : 140)
        hrTSSZones.append(hrTSSZone1a)
        hrTSSZones.append(hrTSSZone1b)
        hrTSSZones.append(hrTSSZone1c)
        hrTSSZones.append(hrTSSZone2a)
        hrTSSZones.append(hrTSSZone2b)
        hrTSSZones.append(hrTSSZone3)
        hrTSSZones.append(hrTSSZone4)
        hrTSSZones.append(hrTSSZone5a)
        hrTSSZones.append(hrTSSZone5b)
        hrTSSZones.append(hrTSSZone5c)
        
        for i in 4...22 {
            //HR 40 to 220, strps of 10
            let hrHZone = Zone (name: "HRHistZ\(i*10)", minValue: Double(i * 10), maxValue: Double((i + 1) * 10), TSSVal: 0)
            hrHistogramZones.append(hrHZone)
        }
        
        //SwimZones
        let swimZone1 = Zone(name: "1 Low", minValue : 0, maxValue: 0.5, TSSVal : 50)
        let swimZone2 = Zone(name: "2 Med", minValue : 0.5, maxValue: 0.6, TSSVal : 75)
        let swimZone3 = Zone(name: "3 High", minValue : 0.6, maxValue: 0.7, TSSVal : 90)
        let swimZone4 = Zone(name: "4 Extreme", minValue : 0.7, maxValue: 2, TSSVal : 100)
        swimZones.append(swimZone1)
        swimZones.append(swimZone2)
        swimZones.append(swimZone3)
        swimZones.append(swimZone4)
    }
    
    
    mutating func addRecord (hr : Double, timeInZone : Double){
        for (index, zone) in hrZones.enumerated() {
            if (hr > zone.minValue) && (hr <= zone.maxValue) {
                self.hrZones[index].addTimeToZone(timeToAdd: timeInZone)
            }
        }
        
        for (index, zone) in hrTSSZones.enumerated() {
            if (hr > zone.minValue) && (hr <= zone.maxValue) {
                self.hrTSSZones[index].addTimeToZone(timeToAdd: timeInZone)
            }
        }
        
        for (index, zone) in hrHistogramZones.enumerated() {
            if (hr >= zone.minValue) && (hr < zone.maxValue) {
                self.hrHistogramZones[index].addTimeToZone(timeToAdd: timeInZone)
            }
        }
        
    } //addRecord
    
    
    mutating func addSwimRecord (time: Double, Distance : Double) {
        let speed = Distance / time
        for (index, zone) in swimZones.enumerated() {
            if (speed > zone.minValue) && (speed <= zone.maxValue) {
                self.swimZones[index].addTimeToZone(timeToAdd: time)
            }
        }
    } //addSwimRecord
    
    
    func hrTSS () -> Double {
        var hrTSSs = 0.0
        for zone in hrTSSZones {
            hrTSSs += zone.TSSScore()
        }
        return hrTSSs / 3600
    } //hrTSS
    
    
    func swimTSS () -> Double {
        var swimTSSs = 0.0
        for zone in swimZones {
            swimTSSs += zone.TSSScore()
        }
        return swimTSSs / 3600
    } //swimTSS
    
}
