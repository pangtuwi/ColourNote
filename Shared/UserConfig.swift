//
//  UserConfig.swift
//  FitForm
//
//  Created by Paul Williams on 06/12/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation

struct UserConfig : Codable {
    var FTP : Int
    var hrTSSZones = [Zone]()
    
    init () {
        FTP = 275
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
    }
}

