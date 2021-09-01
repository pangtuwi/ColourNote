//
//  RunTrackPointRecords.swift
//  FitForm
//
//  Created by Paul Williams on 27/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation
import SQLite

class RunTrackPointRecords {
    
    static let instance = RunTrackPointRecords()
    private let db: Connection?
    
    let runTrackPoints = Table("runtrackpoints")
    let startTime = Expression<Int>("starttime")
    let timeStamp = Expression<Int>("timestamp")
    let heartRate = Expression<Double>("heartrate")
    let distance = Expression<Double>("distance")
    let altitude = Expression<Double>("altitude")
    let speed = Expression<Double>("speed")
    let cadence = Expression<Double>("cadence")
    let latitude = Expression<Double>("latitude")
    let longitude = Expression<Double>("longitude")
    
    private init() {
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
            ).first!
        do {
            db = try Connection("\(path)/fitform.sqlite3")
        } catch {
            db = nil
            print ("Unable to open database")
        }
        createTable()
    }  //init
    
    
    func createTable() {
        // try! db!.run(runTrackPoints.drop())
        do {
            print ("Creating Run TrackPoint Table")
            try db!.run(runTrackPoints.create(ifNotExists: true) { table in
                table.column(startTime)
                table.column(timeStamp, primaryKey: true)
                table.column(heartRate)
                table.column(distance)
                table.column(altitude)
                table.column(speed)
                table.column(cadence)
                table.column(latitude)
                table.column(longitude)
                
            })
        } catch {
            print("Unable to create runTrackPoints table")
        }
    } //createTable

    
    func runRecordExists (cStartTime : Int) -> Bool {
        do {
            for _ in try db!.prepare(self.runTrackPoints.filter(startTime == cStartTime)) {
                return true
            }
        } catch {
            print("runTrackRecordExists failed")
        }
        return false
    }  // runRecordExists
    
    
    func getRunRecords(searchStartTime : Int) -> [RunTrackPoint] {
        var runTrackPoints = [RunTrackPoint]()
        
        do {
            for runTrackPoint in try db!.prepare(self.runTrackPoints.filter(startTime == searchStartTime)) {
                runTrackPoints.append(RunTrackPoint(
                    startTime: runTrackPoint[startTime],
                    timeStamp: runTrackPoint[timeStamp],
                    heartRate: runTrackPoint[heartRate],
                    distance: runTrackPoint[distance],
                    altitude: runTrackPoint[altitude],
                    speed: runTrackPoint[speed],
                    cadence: runTrackPoint[cadence],
                    latitude: runTrackPoint[latitude],
                    longitude: runTrackPoint[longitude]))

            }
            runTrackPoints.sort { $0.timeStamp < $1.timeStamp }
        } catch {
            print("getRunTrackPoints select failed")
        }
        
        return runTrackPoints
    } //getRunTrackPoints
    
    
   func printRunTrackPointRecords() {
        print("Printing RunTrackPoint Records...")
        do {
            for runTrackPoint in try db!.prepare(self.runTrackPoints) {
                print ("\(runTrackPoint[startTime]) - \(runTrackPoint[timeStamp]) - Speed = \(runTrackPoint[speed])")
            }
        } catch {
            print("Select failed")
        }
        print ("...end of RunTrackPoint Records")
    } //printSwimLaps */
    
    
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
    
    func addRunTrackPoint(newStartTime: Int, newRunTrackPoint : RunTrackPoint) -> Int64? {
        do {
            let insert = runTrackPoints.insert(startTime <- newStartTime, timeStamp <- Int(newRunTrackPoint.timeStamp), heartRate <- newRunTrackPoint.heartRate, distance <- newRunTrackPoint.distance, altitude <- newRunTrackPoint.altitude, speed <- newRunTrackPoint.speed, cadence <- newRunTrackPoint.cadence, latitude <- newRunTrackPoint.latitude, longitude <- newRunTrackPoint.longitude )
            let id = try db!.run(insert)
            print ("Added runTrackPoint at \(newRunTrackPoint.timeStamp)")
            return id
        } catch {
            print("Insert failed - could not add Run TrackPoint")
            return -1
        }
    } //addRunTrackPoint
    
    
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
