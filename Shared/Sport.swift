//
//  Sport.swift
//  FitForm
//
//  Created by Paul Williams on 22/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation

enum Sport : Int {
    case Running  = 1
    case Cycling = 2
    case Hiking = 3
    case Swimming = 4
    case Other = 0
    case TreadmillRunning = 18
    case MountainBiking = 5
    case IndoorCycling = 25
    case VirtualCycling = 152
    case LapSwimming = 27
    case OpenWaterSwimming = 28


    func description () -> String {
        switch self {
            case .Running : return "Running"
            case .Cycling : return "Cycling"
            case .Hiking : return "Hiking"
            case .Swimming : return "Swimming"
            case .TreadmillRunning : return "Treadmill Running"
            case .MountainBiking : return "Mountain Biking"
            case .IndoorCycling : return "Indoor Cycling"
            case .VirtualCycling : return "Virtual Cycling"
            case .LapSwimming : return "Lap Swimming"
            case .OpenWaterSwimming : return "Open Water Swimming"
            default: return "Unknown Sport"
        }
    } //sportString
    
    func shouldMap () -> Bool {
        //Should activity have coordinates availabel for a map?
        switch self {
            case .Running : return true
            case .Cycling : return true
            case .Hiking : return true
            case .Swimming : return false
            case .TreadmillRunning : return false
            case .MountainBiking : return true
            case .IndoorCycling : return false
            case .VirtualCycling : return true
            case .LapSwimming : return false
            case .OpenWaterSwimming : return true
            default: return true
        }
    } //ShouldMap
    
    func isSwim () -> Bool {
        //is it a swim?
        switch self {
        case .Running : return false
        case .Cycling : return false
        case .Hiking : return false
        case .Swimming : return true
        case .TreadmillRunning : return false
        case .MountainBiking : return false
        case .IndoorCycling : return false
        case .VirtualCycling : return false
        case .LapSwimming : return true
        case .OpenWaterSwimming : return true
        default: return false
        }
    } //ShouldMap
}
