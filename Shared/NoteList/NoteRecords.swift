//
//  ActivityRecords.swift
//  FitForm
//
//  Created by Paul Williams on 21/08/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

// https://www.raywenderlich.com/385-sqlite-with-swift-tutorial-getting-started
// https://www.raywenderlich.com/3137-sqlite-tutorial-for-ios-creating-and-scripting
// https://www.sitepoint.com/managing-data-in-ios-apps-with-sqlite/
// database stored default at /Users/paulwilliams/Library/Containers/home.FitForm/Data


import Foundation

import SQLite

class NoteRecords {
    
    static let instance = NoteRecords()
    
    private var db: Connection?
    
    //private var saveTime : Int
    
    private let concurrentDBQueue =
        DispatchQueue(
            label: "com.efrt.serverqueue",
            attributes: .concurrent)
    
    let dbName = "colornote.db"
    
    let notes = Table("notes")
    let noteId = Expression<Int>("_id")
    let noteName = Expression<String>("title")
    let editedTime = Expression<Int>("modified_date")
    let noteText = Expression<String>("note")
    let colorIndex = Expression<Int>("color_index")
    //let filename = Expression<String>("filename")
    //let sport = Expression<Int>("sport")
    //let duration = Expression<Int>("duration")
    //let distance = Expression<Int>("distance")
    //let tss = Expression<Int>("tss")
    //let ignore = Expression<Bool>("ignore")
    
    
    private init() {
        /*let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
            ).first! */
        
        //let fileURL = "\(path)/colornote.db""
        var fileURL = Bundle.main.path(forResource:"colornote", ofType:"db") ?? "Not Found"
        print(fileURL)
        do {
            print ("Attempting to open \(fileURL)")
            db = try Connection(fileURL)
            //try db!.run(activities.drop())
            // remove entries that had been triggered but not finished
            // _ = deleteActivity(startTime: 0)
            //dont require this any more since using update not just add and delete
            print ("opened ColorNote Database")
        } catch {
            print ("Unable to open ColorNote database")
            db = nil

        }
        
        createTable()
    }
    
    
    func createTable() {
        do {
            try db!.run(notes.create(ifNotExists: true) { table in
                table.column(noteId)
                table.column(noteName)
                table.column(editedTime)
                table.column(noteText)
                table.column(colorIndex)
               // table.column(ignore)
            })
        } catch {
            print("Unable to create table in NoteRecords")
        }
    } //createTable
    
    
    func noteExists (searchId : Int) -> Bool {
      //  var result : Bool = false
        
       /* concurrentDBQueue.async(flags: .barrier) { [weak self] in
            // 1
            guard let self = self else {
                return
            } */
            
            do {
                for _ in try self.db!.prepare(self.notes.filter(self.noteId == searchId)) {
                    return true
                }
            } catch {
                print("search failed in NoteRecords.noteExists")
            }
           // result = true
           
        
        return false
    }  //NoteExists

    
    func getNotes() -> [Note] {
        var notez = [Note]()
    
            do {
                for note in try self.db!.prepare(self.notes) {
                        notez.append(Note(
                        noteId : note[self.noteId],
                        noteName : note[self.noteName],
                        editedTime: note[self.editedTime],
                        noteText: note[self.noteText],
                        colorIndex: note[self.colorIndex]))
            
                }
                
            } catch {
                print("Select failed in NoteRecords.GetNotes() ")
            }
        print ("got a total of \(notez.count) notes")
        return notez
        
    } //getActivities
    
    
  /*  func getActivitiesIgnore() -> [Activity] {
        //Same as GetActivities except leaves out "ignore"
        var activities = [Activity]()
        
        do {
            for activity in try self.db!.prepare(self.activities.filter(ignore == false)) {
                activities.append(Activity(
                    activityId : activity[self.activityId],
                    activityName : activity[self.activityName],
                    startTime: activity[self.starttime],
                    filename: activity[self.filename],
                    sport: activity[self.sport],
                    duration: activity[self.duration],
                    distance : activity[self.distance],
                    tss : activity[self.tss],
                    ignore : activity[self.ignore]))
            }
            
        } catch {
            print("Select failed in ActivityRecords.GetActivitiesIgnore() ")
        }
        // print ("got a total of \(activities.count) activities")
        return activities
        
    } //getActivities */
    
    
    /*func getListOfActivitiesWithoutTSS() -> [Int] {
        //Activities are set to TSS = -1 before EFRT is loaded
        //This function fetches a list of these activities
        //var activities = [Activity]()
        var list = [Int]()
        do {
            for activity in try db!.prepare(self.activities.filter(tss == -1).filter(ignore == false)) {
                list.append(activity[activityId])
            }
        } catch {
            print("Select failed")
        }
        return list
    } //getActivitiesWithoutTSS
    
    
    func getSportActivities(sportInt : Int) -> [Activity] {
        var activities = [Activity]()
        
        do {
            for activity in try db!.prepare(self.activities.filter(sport == sportInt)) {
                activities.append(Activity(
                    activityId : activity[activityId],
                    activityName : activity[activityName],
                    startTime: activity[starttime],
                    filename: activity[filename],
                    sport: activity[sport],
                    duration: activity[duration],
                    distance : activity[distance],
                    tss : activity[tss],
                    ignore : activity[ignore]))
            }
        } catch {
            print("Select failed")
        }
        return activities
    } //getSportActivities
    
    
    func getActivitiesSince(timeStamp : Int) -> [Activity] {
        var activitiesFound = [Activity]()
        
        do {
            for activity in try self.db!.prepare(self.activities.filter(self.starttime > timeStamp).filter(ignore == false)) {
                activitiesFound.append(Activity(
                    activityId : activity[activityId],
                    activityName : activity[activityName],
                    startTime: activity[starttime],
                    filename: activity[filename],
                    sport: activity[sport],
                    duration: activity[duration],
                    distance : activity[distance],
                    tss : activity[tss],
                    ignore : activity[ignore]))
            }
        } catch {
            print("Select failed in getActivitiesSince in ActivitiesRecords.swift")
        }
        
        return activitiesFound
    } //getActivitiesSince
    
    
    func getLatestActivity() -> Activity? {
        var activities = getActivitiesIgnore()
        activities.sort { $0.startTime > $1.startTime }
        if activities.count > 0 {
            return activities[0]
        } else {
          return nil
        }
     
    } //getLatestActivity
     
     
    */
    
    func getLatestNote() -> Note? {
        var latestNotes = getNotes()
        latestNotes.sort { $0.editedTime > $1.editedTime }
        if latestNotes.count > 0 {
            return latestNotes[0]
        } else {
          return nil
        }
     
    } //getLatestActivity
    /*
    
    func getActivityWithStartTime(startTime : Int) -> Activity? {
        //ToDo : Fix bug where this fucntion throws Thread 1: Fatal error: 'try!' expression unexpectedly raised an error: database is locked (code: 5)
        var activitiesFound = [Activity]()
            do {
                for activity in try self.db!.prepare(self.activities.filter(self.starttime == startTime)) {
                    activitiesFound.append(Activity(
                        activityId : activity[self.activityId],
                        activityName : activity[self.activityName],
                        startTime: activity[self.starttime],
                        filename: activity[self.filename],
                        sport: activity[self.sport],
                        duration: activity[self.duration],
                        distance : activity[self.distance],
                        tss : activity[self.tss],
                        ignore : activity[self.ignore]))
                }
            } catch {
                print("Select failed")
            }
      //  }
        
        if activitiesFound.count == 0 {
            return nil
        } else {
            return activitiesFound[0]
        }
    } //getActivityWithStartTime
 
    
    
    func getActivity(searchActivityId : Int) -> Activity? {
        //ToDo : Fix bug where this fucntion throws Thread 1: Fatal error: 'try!' expression unexpectedly raised an error: database is locked (code: 5)
        var activitiesFound = [Activity]()
        do {
            for activity in try self.db!.prepare(self.activities.filter(self.activityId == searchActivityId)) {
                activitiesFound.append(Activity(
                    activityId : activity[self.activityId],
                    activityName : activity[self.activityName],
                    startTime: activity[self.starttime],
                    filename: activity[self.filename],
                    sport: activity[self.sport],
                    duration: activity[self.duration],
                    distance : activity[self.distance],
                    tss : activity[self.tss],
                    ignore : activity[self.ignore]))
            }
        } catch {
            print("Select failed")
        }
        
        if activitiesFound.count == 0 {
            return nil
        } else {
            return activitiesFound[0]
        }
    } //getActivity (searchActivityId)
     */
     func getNote(searchNoteId : Int) -> Note? {
         //ToDo : Fix bug where this fucntion throws Thread 1: Fatal error: 'try!' expression unexpectedly raised an error: database is locked (code: 5)
         var notesFound = [Note]()
         do {
             for note in try self.db!.prepare(self.notes.filter(self.noteId == searchNoteId)) {
                notesFound.append(Note(
                noteId : note[self.noteId],
                noteName : note[self.noteName],
                editedTime: note[self.editedTime],
                noteText: note[self.noteText],
                colorIndex: note[self.colorIndex]))
             }
         } catch {
             print("Select failed")
         }
         
         if notesFound.count == 0 {
             return nil
         } else {
             return notesFound[0]
         }
     } //getActivity (searchActivityId)
    
    /*
    func getLatestSportActivity(SportInt : Int) -> Activity {
        var activities = getSportActivities(sportInt: SportInt)
        activities.sort { $0.startTime > $1.startTime }
        return activities[0]
    } //getLatestSportActivity

    
    func printActivities() {
      //  var activities = [Activity]()
        
        do {
            for activity in try db!.prepare(self.activities) {
                print ("\(activity[starttime]) - \(activity[tss]) - \(activity[filename])")
            }
        } catch {
            print("Select failed")
        }
        
    } //getActivities
    
    
    func deleteActivity(cActivityId : Int) -> Bool {
        do {
            print ("Attempting to delete Activity at \(cActivityId)")
            let activity = activities.filter(activityId == cActivityId)
            _ = try db!.run(activity.delete())
            return true
        } catch {
            print("Delete failed in ActivityRecords.deleteActivity ")
        }
        return false
    }
    
    
    func deleteAllActivities() {
        do {
            try db!.run(activities.delete())
        } catch {
            print("Activities Table - all activities Deleted")
        }
    } //deleteTable
    
    
    func updateActivity (activity : Activity) -> Int {
        
        var result : Int = -1
        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            // 1
            guard let self = self else {
                return
            }
            
            if self.activityExists(searchId : activity.activityId) {
                do {
                    let existingActivity = self.activities.filter(self.activityId == activity.activityId)
                    let update = existingActivity.update(self.starttime <- activity.startTime, self.filename <- activity.filename, self.sport <- activity.sport, self.duration <- activity.duration, self.distance <- activity.distance, self.tss <- activity.tss, self.ignore <- activity.ignore)
                    let id = try self.db!.run(update)
                    print ("Updated Activity with Id \(activity.activityId)")
                    result = id
                   // return //id
                } catch {
                    print("update failed in ActivityRecords.update")
                   // return
                }
            } else {
                do {
                    let insert = self.activities.insert(self.activityId <- activity.activityId, self.starttime <- activity.startTime, self.filename <- activity.filename, self.sport <- activity.sport, self.duration <- activity.duration, self.tss <- activity.tss)
                    let id = try self.db!.run(insert)
                    print ("Added Activity with Id \(activity.activityId)")
                    result = Int(id)
                  //  return Int(id)
                } catch {
                    print("Insert failed in Activityrecords.update")
                  //  return -1
                }
            }
        }
        return result
    } //update
     
     
     func updateActivity (changedActivityId : Int, efrt : Efrt) -> Int {
         var result : Int = -1
         concurrentDBQueue.async(flags: .barrier) { [weak self] in
             // 1
             guard let self = self else {
                 return
             }
             
             if self.activityExists(searchId : changedActivityId) {
                 do {
                     let existingActivity = self.activities.filter(self.activityId == changedActivityId)
                     //let update = existingActivity.update(self.starttime <- activity.startTime, self.filename <- activity.filename, self.sport <- activity.sport, self.duration <- activity.duration, self.tss <- activity.tss)
                     //update Duration at same time - needed due to Garmin TCX swim having incorrect duration
                     let dbUpdate = existingActivity.update(self.tss <- Int(efrt.bestTSS()), self.duration <- efrt.duration)
                     let id = try self.db!.run(dbUpdate)
                     DispatchQueue.main.async {
                         NotificationCenter.default.post(name: DataLoaderNotification.contentUpdated, object: nil)
                     }
                     //print ("Updated Activity in local DB with ID \(changedActivityId)")
                     result = id
                     // return //id
                 } catch {
                     print("update failed in ActivityRecords.update")
                     // return
                 }
             } else {
                
                 print("Cant find Activity to update in ActivityRecords.UpdateActivity")
             }
         }
         return result
     } //updateActivity(efrt)
    
    */
    
    func updateNoteText (changedNoteId : Int, newText : String) -> Int {
        var result : Int = -1
        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            // 1
            guard let self = self else {
                return
            }
            
            if self.noteExists(searchId : changedNoteId) {
                do {
                    let existingNote = self.notes.filter(self.noteId == changedNoteId)
                    let saveTime = Int(Date().timeIntervalSince1970)*1000
                    
                    let dbUpdate = existingNote.update(self.noteText <- newText, self.editedTime <- saveTime)
                    let id = try self.db!.run(dbUpdate)
                  /*  DispatchQueue.main.async {
                        NotificationCenter.default.post(name: DataLoaderNotification.contentUpdated, object: nil)
                    }
                   */
                    print ("Updated Note in local DB with ID \(changedNoteId)")
                    result = id
                    // return //id
                } catch {
                    print("update failed in updateNoteText")
                    // return
                }
            } else {
               
                print("Cant find Note to update in NoteRecords.updateNoteText")
            }
        }
        return result
    } //updateActivity(efrt)
    
    
    /*
    
    func setActivityIgnore (changedActivityId : Int, ignore : Bool) -> Int {
        var result : Int = -1
        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            // 1
            guard let self = self else {
                return
            }
            
            if self.activityExists(searchId : changedActivityId) {
                do {
                    let existingActivity = self.activities.filter(self.activityId == changedActivityId)
                    //let update = existingActivity.update(self.starttime <- activity.startTime, self.filename <- activity.filename, self.sport <- activity.sport, self.duration <- activity.duration, self.tss <- activity.tss)
                    //update Duration at same time - needed due to Garmin TCX swim having incorrect duration
                    let dbUpdate = existingActivity.update(self.ignore <- ignore)
                    let id = try self.db!.run(dbUpdate)
                    print ("Ignoring Activity with Id \(changedActivityId)")
                    result = id
                    // return //id
                } catch {
                    print("update failed in ActivityRecords.setActivityIgnore")
                    // return
                }
            } else {
                
                print("Cant find Activity to update in ActivityRecords.setActivityIgnore")
            }
        }
        return result
    } //setActivityIgnore
    
    
    func addTempActivity(newActivity: ActivityListing) -> Int64? {
        var result : Int64 = -1
        
        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            // 1
            guard let self = self else {
                return
            }
            
            do {
                let insert = self.activities.insert(self.activityId <- newActivity.activityId, self.activityName <- newActivity.activityName ?? "No Name", self.starttime <- newActivity.startTime(), self.filename <- "", self.sport <- newActivity.activityType.typeId, self.duration <- Int(newActivity.duration),
                    self.distance <- Int(newActivity.distance),self.tss <- -1, self.ignore <- false)
                let id = try self.db!.run(insert)
                
                result = id
            } catch {
                print("Insert failed in ActivityRecords.addTempActivity")
               // return -1
            }
        }
        return result
    }
    */
    
    
}
