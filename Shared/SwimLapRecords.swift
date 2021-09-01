//
//  SwimLapRecords.swift
//  FitForm
//
//  Created by Paul Williams on 26/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation
import SQLite

class SwimLapRecords {
    
    static let instance = SwimLapRecords()
    private let db: Connection?
    
    let swimLaps = Table("swimlaps")
    let startTime = Expression<Int>("starttime")
    let timeStamp = Expression<Int>("timestamp")
    let lapDistance = Expression<Double>("lapdistance")
    let lapTime = Expression<Double>("laptime")
    
    private init() {
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
            ).first!
        
        print ("database is at \(path)")
        
        do {
            db = try Connection("\(path)/fitform.sqlite3")
        } catch {
            db = nil
            print ("Unable to open database")
        }
        
        createTable()
    }
    
    
    func createTable() {
       // try! db!.run(swimLaps.drop())

        do {
            print ("Creating Swim Laps Table")
            try db!.run(swimLaps.create(ifNotExists: true) { table in
                table.column(startTime)
                table.column(timeStamp, primaryKey: true)
                table.column(lapDistance)
                table.column(lapTime)
            })
        } catch {
            print("Unable to create swimLaps table")
        }
    }
    
    
    func query () {
        // activityExists(cid: 1)
    }
    
    
    func swimRecordExists (cStartTime : Int) -> Bool {
        do {
            for _ in try db!.prepare(self.swimLaps.filter(startTime == cStartTime)) {
                return true
            }
        } catch {
            print("swimRecordExists failed")
        }
        return false
    }  //ActivityExists
    
    
    func getSwimRecords(searchStartTime : Int) -> [SwimLap] {
        var swimLaps = [SwimLap]()
        
        do {
            for swimLap in try db!.prepare(self.swimLaps.filter(startTime == searchStartTime)) {
                swimLaps.append(SwimLap(
                    startTime: swimLap[startTime],
                    timeStamp: swimLap[timeStamp],
                    lapDistance: swimLap[lapDistance],
                    lapTime: swimLap[lapTime]))
            }
            swimLaps.sort { $0.timeStamp > $1.timeStamp }
          //  activities.sort { $0.starttime > $1.starttime }
        } catch {
            print("getSwimRecords select failed")
        }
        
        return swimLaps
    } //getSwimLaps
    
    
    
    func printSwimLaps() {
        print("Printing Swim Lap Records...")
        do {
            for swimLap in try db!.prepare(self.swimLaps) {
                print ("\(swimLap[startTime]) - \(swimLap[timeStamp]) - Dist= \(swimLap[lapDistance])")
            }
        } catch {
            print("Select failed")
        }
        print ("...end of Swim Lap Records")
    } //printSwimLaps
 
    
   /*
    func deleteActivity(startTime: Int) -> Bool {
        do {
            print ("Attempting to delete Activity at \(startTime)")
            let activity = activities.filter(starttime == startTime)
            let delete = try db!.run(activity.delete())
            return true
        } catch {
            print("Delete failed")
        }
        return false
    }
 
 */
    
    func addSwimLap(newSwimLapStartTime: Int, newSwimLap : SwimLap) -> Int64? {
        do {
            let insert = swimLaps.insert(startTime <- newSwimLapStartTime, timeStamp <- Int(newSwimLap.timeStamp), lapDistance <- newSwimLap.lapDistance, lapTime <- newSwimLap.lapTime)
            let id = try db!.run(insert)
            print ("Added swimLap at \(newSwimLapStartTime)")
            return id
        } catch {
            print("Insert failed - could not add Swim Lap")
            return -1
        }
    } //addSwimLap
    
    
/*    func updateActivityFromFITData(cfilename: String, cFITData: FITData) -> Int64? {
        //delete the old one
        let _ = deleteActivity(startTime: Int(cFITData.sessionStartTime))
        //insert the new one
        do {
            let insert = activities.insert(starttime <- Int(cFITData.sessionStartTime), filename <- cfilename, sport <- cFITData.activityTypeInt, duration <- Int(cFITData.total_timer_time), tss <- Int (cFITData.bestTSS()))
            let id = try db!.run(insert)
            print ("Added (in Update) Activity at \(cFITData.sessionStartTime)")
            return id
        } catch {
            print("Insert failed")
            return -1
        }
    } //addActivityFromFITData
    
    
    func addTempActivity(cfilename: String) -> Int64? {
        do {
            let insert = activities.insert(starttime <- 0, filename <- cfilename, sport <- 0, duration <- 0, tss <- 0)
            let id = try db!.run(insert)
            
            return id
        } catch {
            print("Insert failed")
            return -1
        }
    } */
    
}
