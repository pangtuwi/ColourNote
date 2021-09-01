//
//  EfrtActivity.swift
//  FitForm
//
//  Created by Paul Williams on 06/12/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation

struct EfrtActivity : Decodable {
    let activityId : Int
    let activityStartTime : Int
    let efrt : Efrt
    let garminData : GarminData
    let trackPoints : [TrackPoint]?   //Optional as trackpoints may be missing for swim activity
}

struct GarminData : Decodable {
    let activityType : ActivityType
    let startTimeLocal : String
    let duration : Double
}

struct ActivityType : Decodable {
    let typeId : Int
}

