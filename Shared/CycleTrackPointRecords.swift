//
//  CycleTrackPointRecords.swift
//  FitForm
//
//  Created by Paul Williams on 28/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation
import SQLite

class CycleTrackPointRecords {
    
    static let instance = CycleTrackPointRecords()
    private var db: Connection?
    
    let cycleTrackPoints = Table("cycletrackpoints")
    let activityId = Expression<Int>("activityid")
    let timeStamp = Expression<Int>("timestamp")
    let distance = Expression<Double>("distance")
    let latitude = Expression<Double>("latitude")
    let longitude = Expression<Double>("longitude")
    let altitude = Expression<Double>("altitude")
    let heartRate = Expression<Double>("heartrate")
    let speed = Expression<Double>("speed")
    let cadence = Expression<Double>("cadence")
    let power = Expression<Double>("power")
    
    
    private init() {
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
            ).first!
        do {
            db = try Connection("\(path)/fitform.sqlite3")
           // try db!.run(cycleTrackPoints.drop())
        } catch {
            db = nil
            print ("Unable to open database")
        }
        createTable()
    }  //init
    
    
    func createTable() {
        // try! db!.run(runTrackPoints.drop())
        do {
            //print ("Creating Cycle TrackPoint Table")
            try db!.run(cycleTrackPoints.create(ifNotExists: true) { table in
                table.column(activityId)
                table.column(timeStamp, primaryKey: true)
                table.column(heartRate)
                table.column(distance)
                table.column(altitude)
                table.column(speed)
                table.column(power)
                table.column(latitude)
                table.column(longitude)
                
            })
        } catch {
            print("Unable to create cycleTrackPoints table")
        }
    } //createTable
    
    
    func cycleRecordExists (cActivityId : Int) -> Bool {
        do {
            for _ in try db!.prepare(self.cycleTrackPoints.filter(activityId == cActivityId)) {
                return true
            }
        } catch {
            print("cycleTrackRecordExists failed")
        }
        return false
    }  // runRecordExists
    
    
    
    func getCycleRecords(cActivityId : Int) -> [CycleTrackPoint] {
        var cycleTrackPoints = [CycleTrackPoint]()
        
        do {
            for cycleTrackPoint in try db!.prepare(self.cycleTrackPoints.filter(activityId == cActivityId)) {
                cycleTrackPoints.append(CycleTrackPoint(
                    activityId: cycleTrackPoint[activityId],
                    timeStamp: cycleTrackPoint[timeStamp],
                    heartRate: cycleTrackPoint[heartRate],
                    distance: cycleTrackPoint[distance],
                    altitude: cycleTrackPoint[altitude],
                    speed: cycleTrackPoint[speed],
                    power: cycleTrackPoint[power],
                    latitude: cycleTrackPoint[latitude],
                    longitude: cycleTrackPoint[longitude]))
                
            }
            cycleTrackPoints.sort { $1.timeStamp > $0.timeStamp }
        } catch {
            print("getCycleTrackPoints select failed")
        }
        
        return cycleTrackPoints
    } //getCycleTrackPoints
    
    
    
  /*  func printCycleTrackPointRecords() {
        print("Printing CycleTrackPoint Records...")
        do {
            for cycleTrackPoint in try db!.prepare(self.cycleTrackPoints) {
                print ("\(cycleTrackPoint[startTime]) - \(cycleTrackPoint[timeStamp]) - Speed = \(cycleTrackPoint[speed])")
            }
        } catch {
            print("Select failed")
        }
        print ("...end of CycleTrackPoint Records")
    } //printCycleTrackPointRecords */
  
   /* EXAMPLE
     func deleteActivity(startTime: Int) -> Bool {
        do {
            print ("Attempting to delete Activity at \(startTime)")
            let activity = activities.filter(starttime == startTime)
            _ = try db!.run(activity.delete())
            return true
        } catch {
            print("Delete failed ")
        }
        return false
    } */
    
    func deleteActivity(cActivityId: Int) -> Bool {
        do {
            print ("Attempting to delete Activity from CycleTractkRecords at \(cActivityId)")
                let cycleTrackPointstoDelete = cycleTrackPoints.filter(activityId == cActivityId)
             
                    _ = try db!.run(cycleTrackPointstoDelete.delete())
               
                return true

            } catch {
                print("getCycleTrackPoints delete failed")
            }
            
        return false
    }
    
    func deleteAllActivities() {
        do {
            try db!.run(cycleTrackPoints.delete())
        } catch {
            print("CycleTrackPoints Table - all records Deleted")
        }
    } //deleteTable
    
    
    func addCycleTrackPoint(newActivityId: Int, newCycleTrackPoint : CycleTrackPoint) -> Int64? {
        //ToDo: add code to check if point exists before adding it. (update)
        do {
            let insert = cycleTrackPoints.insert(activityId <- newActivityId, timeStamp <- Int(newCycleTrackPoint.timeStamp), heartRate <- newCycleTrackPoint.heartRate, distance <- newCycleTrackPoint.distance, altitude <- newCycleTrackPoint.altitude, speed <- newCycleTrackPoint.speed, power <- newCycleTrackPoint.power, latitude <- newCycleTrackPoint.latitude, longitude <- newCycleTrackPoint.longitude )
            let id = try db!.run(insert)
            //print ("Added CycleTrackPoint at \(newCycleTrackPoint.timeStamp)")
            return id
        } catch {
            print("Insert failed - could not add CycleTrackPoint with activityId \(newActivityId)")
            return -1
        }
    } //addCycleTrackPoint
    
    
}
