//
//  Zone.swift
//  FitForm
//
//  Created by Paul Williams on 08/08/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation

struct Zone : Codable {
    var name : String
    var minValue : Double
    var maxValue : Double
    var timeInZone : Double
    var TSSVal : Double
    
    init (name : String, minValue : Double, maxValue : Double, TSSVal : Double) {
        self.name = name
        self.minValue = minValue
        self.maxValue = maxValue
        self.TSSVal = TSSVal
        self.timeInZone = 0
    }
    
    mutating func addTimeToZone (timeToAdd : Double) {
        self.timeInZone += timeToAdd
    }
    
    func TSSScore () -> Double {
        return timeInZone * TSSVal
    }
}
