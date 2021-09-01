//
//  TrackPoints.swift
//  FitForm
//
//  Created by Paul Williams on 19/12/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation

struct TrackPoint : Decodable {
    let Time :Int
    let Distance : Double
    let Lat : Double
    let Long : Double
    let Alt : Double
    let HR : Double
    let Speed : Double
    let Cadence : Double
    let Power : Double
}
