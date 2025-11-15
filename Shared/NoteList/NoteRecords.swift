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
    let noteId = SQLite.Expression<Int>("_id")
    let noteName = SQLite.Expression<String>("title")
    let editedTime = SQLite.Expression<Int>("modified_date")
    let createdDate = SQLite.Expression<Int>("created_date")
    let noteText = SQLite.Expression<String>("note")
    let colorIndex = SQLite.Expression<Int>("color_index")
    let categoryId = SQLite.Expression<Int>("category_id")
    let noteType = SQLite.Expression<Int>("type")
    let noteNoteType = SQLite.Expression<Int>("note_type")
    let activeState = SQLite.Expression<Int>("active_state")
    let deletedDate = SQLite.Expression<Int?>("deleted_date")
    //let filename = Expression<String>("filename")
    //let sport = Expression<Int>("sport")
    //let duration = Expression<Int>("duration")
    //let distance = Expression<Int>("distance")
    //let tss = Expression<Int>("tss")
    //let ignore = Expression<Bool>("ignore")
    
    
    private init() {

        if copyDatabaseIfNeeded() {
            print("Default database copied")
        }
        openDatabase()
        migrateDatabaseIfNeeded()


        /*let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
            ).first! */

     /*   do {
            try openDatabase()
        } catch {
            print ("Unable to open ColorNote database")
            db = nil
        } */




        //let fileURL = "\(path)/colornote.db""
    /*    var fileURL = Bundle.main.path(forResource:"colornote", ofType:"db") ?? "Not Found"
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

        } */

       // createTable()





    }
    
    //var db: OpaquePointer?

    enum DatabaseError: Error {
        case bundleDatabaseNotFound
        case sqliteError(Int32, String?)
    }
    
    func copyDatabaseIfNeeded() -> Bool {
        // from https://github.com/stephencelis/SQLite.swift/blob/master/Documentation/Index.md#getting-started
        let bundlePath = Bundle.main.url(forResource: "colornote", withExtension: "db")!.path
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let destinationPath = documents + "/" + dbName
        let exists = FileManager.default.fileExists(atPath: destinationPath)

        // Check if we need to replace corrupted database
        let dbVersionKey = "DatabaseVersion"
        let currentDBVersion = 2 // Increment this to force database replacement
        let savedDBVersion = UserDefaults.standard.integer(forKey: dbVersionKey)

        print("=== copyDatabaseIfNeeded check ===")
        print("Database exists: \(exists)")
        print("Saved DB version: \(savedDBVersion)")
        print("Current DB version: \(currentDBVersion)")

        // If DatabaseVersion is already set to current version, don't copy
        // This prevents overwriting user-created blank databases or imported databases
        if savedDBVersion >= currentDBVersion {
            print("Database version is current, skipping auto-copy")
            return false
        }

        if exists && savedDBVersion < currentDBVersion {
            // Remove old corrupted database
            do {
                try FileManager.default.removeItem(atPath: destinationPath)
                print("Removed old database version \(savedDBVersion)")
            } catch {
                print("Error removing old database: \(error)")
            }
        }

        if !FileManager.default.fileExists(atPath: destinationPath) {
            do {
                try FileManager.default.copyItem(atPath: bundlePath, toPath: destinationPath)
                UserDefaults.standard.set(currentDBVersion, forKey: dbVersionKey)
                print("Copied database from Bundle (version \(currentDBVersion))")
                return true
            } catch {
                print("error during file copy: \(error)")
                return false
            }
        } else {
            print("Database already exists in user folder")
            return false
        }
    }

    func openDatabase() {
        do {
    /*    let fileURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("colornote.db") */

        /*    let fileURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("colornote.db")
                //.path
            let fileURLString = fileURL.path

         */

            let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    .appendingPathComponent("colornote.db")
                    .path

            print("attempting to open database at \(fileURL)")


     /*   if sqlite3_open_v2(fileURL.path, &db, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK {
            return
        } */


        try db = Connection(fileURL)

        // Register LOCALIZED collation as a fallback (even though schema doesn't use it)
        // This prevents errors if SQLite.swift cached old schema information
        try? db!.createCollation("LOCALIZED") { (lhs, rhs) -> ComparisonResult in
            return lhs.localizedCaseInsensitiveCompare(rhs)
        }
        print("Database opened successfully")

        } catch {
            db = nil
            print (error)
        }
    }

    func migrateDatabaseIfNeeded() {
        guard let db = db else {
            print("NoteRecords: Database not available for migration")
            return
        }

        let dbSchemaVersionKey = "DatabaseSchemaVersion"
        let currentSchemaVersion = 4 // Increment when adding new migrations
        let savedSchemaVersion = UserDefaults.standard.integer(forKey: dbSchemaVersionKey)

        print("=== Database Migration Check ===")
        print("Current schema version: \(currentSchemaVersion)")
        print("Saved schema version: \(savedSchemaVersion)")

        if savedSchemaVersion < currentSchemaVersion {
            // Run migrations
            if savedSchemaVersion < 3 {
                // Migration to version 3: Add category_id column and categories table
                print("Running migration to version 3: Adding category support")

                do {
                    // Add category_id column to notes table if it doesn't exist
                    try db.execute("ALTER TABLE notes ADD COLUMN category_id INTEGER DEFAULT 0")
                    print("Added category_id column to notes table")
                } catch {
                    print("category_id column may already exist or error: \(error)")
                }

                do {
                    // Create categories table
                    let createCategoriesTableSQL = """
                    CREATE TABLE IF NOT EXISTS categories (
                        category_id INTEGER PRIMARY KEY,
                        category_name TEXT NOT NULL DEFAULT '',
                        color_hex TEXT NOT NULL DEFAULT '#FFFFFF',
                        sort_order INTEGER DEFAULT 0
                    );
                    CREATE INDEX IF NOT EXISTS idx_category_sort ON categories(sort_order);
                    """
                    try db.execute(createCategoriesTableSQL)
                    print("Created categories table")

                    // Insert default categories
                    insertDefaultCategoriesIfNeeded()
                } catch {
                    print("Error creating categories table: \(error)")
                }

                // Update schema version
                UserDefaults.standard.set(3, forKey: dbSchemaVersionKey)
                print("Migration to version 3 completed")
            }

            if savedSchemaVersion < 4 {
                // Migration to version 4: Add soft delete support
                print("Running migration to version 4: Adding soft delete support")

                do {
                    // Add deleted_date column to notes table if it doesn't exist
                    try db.execute("ALTER TABLE notes ADD COLUMN deleted_date INTEGER DEFAULT NULL")
                    print("Added deleted_date column to notes table")
                } catch {
                    print("deleted_date column may already exist or error: \(error)")
                }

                // Update schema version
                UserDefaults.standard.set(4, forKey: dbSchemaVersionKey)
                print("Migration to version 4 completed")
            }
        } else {
            print("Database schema is up to date")
        }
    }

    func insertDefaultCategoriesIfNeeded() {
        guard let db = db else { return }

        let defaultCategories = Category.getDefaultCategories()

        for category in defaultCategories {
            do {
                let sql = """
                INSERT OR IGNORE INTO categories (category_id, category_name, color_hex, sort_order)
                VALUES (?, ?, ?, ?)
                """
                try db.run(sql, category.categoryId, category.categoryName, category.colorHex, category.sortOrder)
            } catch {
                print("Error inserting default category: \(error)")
            }
        }
        print("Default categories inserted")
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
                // Only get active notes (not deleted)
                for note in try self.db!.prepare(self.notes.filter(self.activeState == 0)) {
                        notez.append(Note(
                        noteId : note[self.noteId],
                        noteName : note[self.noteName],
                        editedTime: note[self.editedTime],
                        noteText: note[self.noteText],
                        colorIndex: note[self.colorIndex],
                        categoryId: note[self.categoryId],
                        isDeleted: false,
                        deletedDate: nil))

                }

            } catch {
                print("Select failed in NoteRecords.GetNotes() ")
            }
        print ("got a total of \(notez.count) notes")
        return notez

    } //getActivities

    func getDeletedNotes() -> [Note] {
        var deletedNotez = [Note]()

            do {
                // Only get deleted notes (active_state = 1), ordered by deleted_date descending
                for note in try self.db!.prepare(self.notes.filter(self.activeState == 1).order(self.deletedDate.desc)) {
                        deletedNotez.append(Note(
                        noteId : note[self.noteId],
                        noteName : note[self.noteName],
                        editedTime: note[self.editedTime],
                        noteText: note[self.noteText],
                        colorIndex: note[self.colorIndex],
                        categoryId: note[self.categoryId],
                        isDeleted: true,
                        deletedDate: note[self.deletedDate]))

                }

            } catch {
                print("Select failed in NoteRecords.getDeletedNotes() ")
            }
        print ("got a total of \(deletedNotez.count) deleted notes")
        return deletedNotez

    } //getDeletedNotes

    func getAllNotes() -> [Note] {
        // Get ALL notes (both active and deleted) for backup purposes
        var allNotez = [Note]()

            do {
                // Get all notes without filtering by active_state
                for note in try self.db!.prepare(self.notes) {
                        let isDeleted = (note[self.activeState] == 1)
                        allNotez.append(Note(
                        noteId : note[self.noteId],
                        noteName : note[self.noteName],
                        editedTime: note[self.editedTime],
                        noteText: note[self.noteText],
                        colorIndex: note[self.colorIndex],
                        categoryId: note[self.categoryId],
                        isDeleted: isDeleted,
                        deletedDate: note[self.deletedDate]))

                }

            } catch {
                print("Select failed in NoteRecords.getAllNotes() ")
            }
        print ("got a total of \(allNotez.count) notes (including deleted)")
        return allNotez

    } //getAllNotes


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
                colorIndex: note[self.colorIndex],
                categoryId: note[self.categoryId]))
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
                    let saveTime = Int(Date().timeIntervalSince1970)*1000

                    // Use raw SQL to avoid collation issues
                    let sql = """
                    UPDATE notes SET note = ?, modified_date = ? WHERE _id = ?
                    """
                    try self.db!.run(sql, newText, saveTime, changedNoteId)
                  /*  DispatchQueue.main.async {
                        NotificationCenter.default.post(name: DataLoaderNotification.contentUpdated, object: nil)
                    }
                   */
                    print ("Updated Note in local DB with ID \(changedNoteId)")
                    result = changedNoteId
                    // return //id
                } catch {
                    print("update failed in updateNoteText: \(error)")
                    // return
                }
            } else {

                print("Cant find Note to update in NoteRecords.updateNoteText")
            }
        }
        return result
    } //updateActivity(efrt)

    func insertNote(note: Note) -> Int64 {
        var result: Int64 = -1
        let semaphore = DispatchSemaphore(value: 0)

        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                semaphore.signal()
                return
            }

            do {
                // Use raw SQL to bypass COLLATE LOCALIZED issue
                let sql = """
                INSERT INTO notes (_id, title, created_date, modified_date, note, color_index, category_id, type, note_type)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """
                try self.db!.run(sql, note.noteId, note.noteName, note.editedTime, note.editedTime, note.noteText, note.colorIndex, note.categoryId, 0, 0)
                print("Inserted Note with ID \(note.noteId)")
                result = Int64(note.noteId)
            } catch {
                print("Insert failed in NoteRecords.insertNote: \(error)")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    } //insertNote

    func updateNoteTitle(changedNoteId: Int, newTitle: String) -> Int {
        var result: Int = -1
        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }

            if self.noteExists(searchId: changedNoteId) {
                do {
                    let saveTime = Int(Date().timeIntervalSince1970) * 1000

                    // Use raw SQL to avoid collation issues
                    let sql = """
                    UPDATE notes SET title = ?, modified_date = ? WHERE _id = ?
                    """
                    try self.db!.run(sql, newTitle, saveTime, changedNoteId)
                    print("Updated Note title in local DB with ID \(changedNoteId)")
                    result = changedNoteId
                } catch {
                    print("Update failed in updateNoteTitle: \(error)")
                }
            } else {
                print("Can't find Note to update in NoteRecords.updateNoteTitle")
            }
        }
        return result
    } //updateNoteTitle

    func updateNoteCategory(changedNoteId: Int, newCategoryId: Int) -> Int {
        var result: Int = -1
        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                return
            }

            if self.noteExists(searchId: changedNoteId) {
                do {
                    let saveTime = Int(Date().timeIntervalSince1970) * 1000

                    // Use raw SQL to avoid collation issues
                    let sql = """
                    UPDATE notes SET category_id = ?, modified_date = ? WHERE _id = ?
                    """
                    try self.db!.run(sql, newCategoryId, saveTime, changedNoteId)
                    print("Updated Note category in local DB with ID \(changedNoteId)")
                    result = changedNoteId
                } catch {
                    print("Update failed in updateNoteCategory: \(error)")
                }
            } else {
                print("Can't find Note to update in NoteRecords.updateNoteCategory")
            }
        }
        return result
    } //updateNoteCategory

    // Soft delete: Mark note as deleted without removing from database
    func softDeleteNote(noteId: Int) -> Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)

        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                semaphore.signal()
                return
            }

            do {
                let deletedTime = Int(Date().timeIntervalSince1970) * 1000
                // Use raw SQL to avoid collation issues
                let sql = "UPDATE notes SET active_state = 1, deleted_date = ? WHERE _id = ?"
                try self.db!.run(sql, deletedTime, noteId)
                print("Soft deleted Note with ID \(noteId)")
                result = true
            } catch {
                print("Soft delete failed in NoteRecords.softDeleteNote: \(error)")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    } //softDeleteNote

    // Restore a deleted note
    func undeleteNote(noteId: Int) -> Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)

        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                semaphore.signal()
                return
            }

            do {
                // Use raw SQL to avoid collation issues
                let sql = "UPDATE notes SET active_state = 0, deleted_date = NULL WHERE _id = ?"
                try self.db!.run(sql, noteId)
                print("Restored Note with ID \(noteId)")
                result = true
            } catch {
                print("Restore failed in NoteRecords.undeleteNote: \(error)")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    } //undeleteNote

    // Permanently delete a note (hard delete)
    func permanentlyDeleteNote(noteId: Int) -> Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)

        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                semaphore.signal()
                return
            }

            do {
                // Use raw SQL to avoid collation issues
                let sql = "DELETE FROM notes WHERE _id = ?"
                try self.db!.run(sql, noteId)
                print("Permanently deleted Note with ID \(noteId)")
                result = true
            } catch {
                print("Permanent delete failed in NoteRecords.permanentlyDeleteNote: \(error)")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    } //permanentlyDeleteNote

    // Empty trash - permanently delete all soft-deleted notes
    func emptyTrash() -> Int {
        var deletedCount = 0
        let semaphore = DispatchSemaphore(value: 0)

        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                semaphore.signal()
                return
            }

            do {
                // Use raw SQL to delete all notes where active_state = 1
                let sql = "DELETE FROM notes WHERE active_state = 1"
                try self.db!.run(sql)
                // Get the number of changes (rows deleted)
                deletedCount = self.db!.changes
                print("Emptied trash: permanently deleted \(deletedCount) notes")
            } catch {
                print("Empty trash failed in NoteRecords.emptyTrash: \(error)")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return deletedCount
    } //emptyTrash

    // Legacy method for compatibility - redirects to soft delete
    func deleteNote(noteId: Int) -> Bool {
        return softDeleteNote(noteId: noteId)
    } //deleteNote

    // Set deletion status on a note (for import/restore)
    func setNoteDeletionStatus(noteId: Int, isDeleted: Bool, deletedDate: Int?) -> Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)

        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                semaphore.signal()
                return
            }

            do {
                if isDeleted {
                    // Mark as deleted
                    let deletedTime = deletedDate ?? Int(Date().timeIntervalSince1970) * 1000
                    let sql = "UPDATE notes SET active_state = 1, deleted_date = ? WHERE _id = ?"
                    try self.db!.run(sql, deletedTime, noteId)
                    print("Set Note \(noteId) as deleted")
                } else {
                    // Mark as active
                    let sql = "UPDATE notes SET active_state = 0, deleted_date = NULL WHERE _id = ?"
                    try self.db!.run(sql, noteId)
                    print("Set Note \(noteId) as active")
                }
                result = true
            } catch {
                print("Failed to set deletion status in NoteRecords.setNoteDeletionStatus: \(error)")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    } //setNoteDeletionStatus
    
    
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
