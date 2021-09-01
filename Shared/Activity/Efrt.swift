//
//  Efrt.swift
//  FitForm
//
//  Created by Paul Williams on 19/12/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation

struct Efrt : Decodable {
    let distance : Double
    let duration : Int
    let avgHR : Int
    let maxHR : Double
    let hrHist : [Histogram]
    let hrTSS : Double
    let swimTSS : Double
    let powerTSS : Double
    let avgPower : Double
    let maxPower : Double
    let NP : Double
    let bestTimes : [BestTimesArray]
    let avgCadence : Int
    let maxCadence : Int
    
    init() {
        distance = 0
        duration = 0
        avgHR = 0
        maxHR = 0
        hrHist = []
        hrTSS = 0
        swimTSS = 0
        powerTSS = 0
        avgPower = 0
        maxPower = 0
        NP = 0
        bestTimes = []
        avgCadence = 0
        maxCadence = 0
    }
    
    struct Histogram : Decodable {
        let pot : String
        let count : Int
    }
    
    struct BestTimesArray : Decodable {
        let d : Int
        let minTime : Int
        let minTime100 : Double
    }
    
    func bestTSS () -> Double {
        // Chooses Best TSS value to use for fitness calculations
        if powerTSS > 0  {
            return powerTSS
        } else if swimTSS > 0 {
            return swimTSS
        } else if hrTSS > 0 {
            return hrTSS
        } else {
            return 0
        }
    } // bestTSS
}

