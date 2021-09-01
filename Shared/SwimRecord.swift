//
//  SwimRecord.swift
//  FitForm
//
//  Created by Paul Williams on 26/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation
import RealmSwift

class SwimRecord: Object {
    dynamic var startTime = 0
    dynamic var timeStamp = 0
    dynamic var lapDistance = 0.0
    dynamic var lapTime = 0.0
}
