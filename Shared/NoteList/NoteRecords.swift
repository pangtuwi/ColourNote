//
//  NoteRecords.swift
//  ColourNote
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
    let noteUUID = SQLite.Expression<String?>("uuid")
    let categoryId = SQLite.Expression<Int>("category_id")
    let noteType = SQLite.Expression<Int>("type")
    let noteNoteType = SQLite.Expression<Int>("note_type")
    let activeState = SQLite.Expression<Int>("active_state")
    let deletedDate = SQLite.Expression<Int?>("deleted_date")
    let contentFormat = SQLite.Expression<String?>("content_format")


    private init() {
        openDatabase()
        migrateDatabaseIfNeeded()
    }
    
    //var db: OpaquePointer?

    enum DatabaseError: Error {
        case sqliteError(Int32, String?)
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

        // Enable WAL mode for better concurrent access
        try db?.execute("PRAGMA journal_mode = WAL")

        // Register LOCALIZED collation as a fallback (even though schema doesn't use it)
        // This prevents errors if SQLite.swift cached old schema information
        try? db!.createCollation("LOCALIZED") { (lhs, rhs) -> ComparisonResult in
            return lhs.localizedCaseInsensitiveCompare(rhs)
        }
        print("Database opened successfully with WAL mode")

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
        let currentSchemaVersion = 10 // Increment when adding new migrations
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

            if savedSchemaVersion < 5 {
                // Migration to version 5: Add Markdown support
                print("Running migration to version 5: Adding Markdown support")

                do {
                    // Add content_format column to notes table if it doesn't exist
                    try db.execute("ALTER TABLE notes ADD COLUMN content_format TEXT DEFAULT 'markdown'")
                    print("Added content_format column to notes table")
                } catch {
                    print("content_format column may already exist or error: \(error)")
                }

                // Update schema version
                UserDefaults.standard.set(5, forKey: dbSchemaVersionKey)
                print("Migration to version 5 completed")
            }

            if savedSchemaVersion < 6 {
                // Migration to version 6: Add cloud sync support
                print("Running migration to version 6: Adding cloud sync support")

                do {
                    // Create sync_mappings table for tracking local-to-cloud ID mappings
                    let createSyncMappingsSQL = """
                    CREATE TABLE IF NOT EXISTS sync_mappings (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        local_id INTEGER NOT NULL,
                        cloud_id TEXT NOT NULL,
                        entity_type TEXT NOT NULL,
                        last_synced INTEGER,
                        sync_status TEXT DEFAULT 'pending_upload',
                        created_at INTEGER NOT NULL,
                        modified_at INTEGER NOT NULL
                    );
                    CREATE INDEX IF NOT EXISTS idx_sync_local ON sync_mappings(local_id, entity_type);
                    CREATE INDEX IF NOT EXISTS idx_sync_cloud ON sync_mappings(cloud_id);
                    CREATE UNIQUE INDEX IF NOT EXISTS idx_sync_unique ON sync_mappings(local_id, entity_type);
                    """
                    try db.execute(createSyncMappingsSQL)
                    print("Created sync_mappings table")
                } catch {
                    print("Error creating sync_mappings table: \(error)")
                }

                // Update schema version
                UserDefaults.standard.set(6, forKey: dbSchemaVersionKey)
                print("Migration to version 6 completed")
            }

            if savedSchemaVersion < 7 {
                // Migration to version 7: Add UUID to notes table
                print("Running migration to version 7: Adding UUID to notes")

                do {
                    // Add uuid column to notes table
                    try db.execute("ALTER TABLE notes ADD COLUMN uuid TEXT")
                    print("Added uuid column to notes table")

                    // Generate UUIDs for existing notes
                    for row in try db.prepare("SELECT _id FROM notes WHERE uuid IS NULL") {
                        let noteId = row[0] as! Int64
                        let newUUID = UUID().uuidString
                        try db.run("UPDATE notes SET uuid = ? WHERE _id = ?", newUUID, noteId)
                    }
                    print("Generated UUIDs for existing notes")
                } catch {
                    print("Error in migration to version 7: \(error)")
                }

                // Update schema version
                UserDefaults.standard.set(7, forKey: dbSchemaVersionKey)
                print("Migration to version 7 completed")
            }

            if savedSchemaVersion < 8 {
                // Migration to version 8: Add UUID to categories table
                print("Running migration to version 8: Adding UUID to categories")

                do {
                    // Add uuid column to categories table
                    try db.execute("ALTER TABLE categories ADD COLUMN uuid TEXT")
                    print("Added uuid column to categories table")

                    // Generate UUIDs for existing categories
                    for row in try db.prepare("SELECT category_id FROM categories WHERE uuid IS NULL") {
                        let categoryId = row[0] as! Int64
                        let newUUID = UUID().uuidString
                        try db.run("UPDATE categories SET uuid = ? WHERE category_id = ?", newUUID, categoryId)
                    }
                    print("Generated UUIDs for existing categories")
                } catch {
                    print("Error in migration to version 8: \(error)")
                }

                // Update schema version
                UserDefaults.standard.set(8, forKey: dbSchemaVersionKey)
                print("Migration to version 8 completed")
            }

            if savedSchemaVersion < 9 {
                // Migration to version 9: Deprecate color_index column (cannot drop in SQLite)
                // The column remains in the table but is no longer used by the app
                // Notes now get their color from their assigned category
                print("Running migration to version 9: Deprecating color_index")
                print("Note: color_index column retained for backward compatibility but no longer used")

                // Update schema version
                UserDefaults.standard.set(9, forKey: dbSchemaVersionKey)
                print("Migration to version 9 completed")
            }

            if savedSchemaVersion < 10 {
                // Migration to version 10: Add UUID index on notes and etag column to sync_mappings
                print("Running migration to version 10: Adding UUID index and etag support")

                do {
                    // Create index on uuid for faster lookups
                    try db.execute("CREATE INDEX IF NOT EXISTS idx_notes_uuid ON notes(uuid)")
                    print("Created index on notes.uuid column")
                } catch {
                    print("Error creating notes uuid index: \(error)")
                }

                do {
                    // Add etag column to sync_mappings table
                    try db.execute("ALTER TABLE sync_mappings ADD COLUMN etag TEXT DEFAULT NULL")
                    print("Added etag column to sync_mappings table")
                } catch {
                    print("etag column may already exist or error: \(error)")
                }

                // Update schema version
                UserDefaults.standard.set(10, forKey: dbSchemaVersionKey)
                print("Migration to version 10 completed")
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
                //table.column(colorIndex)
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
                        uuid: note[self.noteUUID],
                        noteName : note[self.noteName],
                        editedTime: note[self.editedTime],
                        noteText: note[self.noteText],
                        categoryId: note[self.categoryId],
                        isDeleted: false,
                        deletedDate: nil,
                        contentFormat: note[self.contentFormat] ?? "markdown"))

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
                        uuid: note[self.noteUUID],
                        noteName : note[self.noteName],
                        editedTime: note[self.editedTime],
                        noteText: note[self.noteText],
                        categoryId: note[self.categoryId],
                        isDeleted: true,
                        deletedDate: note[self.deletedDate],
                        contentFormat: note[self.contentFormat] ?? "markdown"))

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
                        uuid: note[self.noteUUID],
                        noteName : note[self.noteName],
                        editedTime: note[self.editedTime],
                        noteText: note[self.noteText],
                        categoryId: note[self.categoryId],
                        isDeleted: isDeleted,
                        deletedDate: note[self.deletedDate],
                        contentFormat: note[self.contentFormat] ?? "markdown"))

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
                let isDeleted = (note[self.activeState] == 1)
                notesFound.append(Note(
                noteId : note[self.noteId],
                uuid: note[self.noteUUID],
                noteName : note[self.noteName],
                editedTime: note[self.editedTime],
                noteText: note[self.noteText],
                categoryId: note[self.categoryId],
                isDeleted: isDeleted,
                deletedDate: note[self.deletedDate],
                contentFormat: note[self.contentFormat] ?? "markdown"))
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
                         NotificationCenter.default.post(name: NotesNotification.contentUpdated, object: nil)
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
                        NotificationCenter.default.post(name: NotesNotification.contentUpdated, object: nil)
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
                // Note: color_index column kept for backward compatibility but always set to 0
                let sql = """
                INSERT INTO notes (_id, uuid, title, created_date, modified_date, note, color_index, category_id, type, note_type, content_format)
                VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?)
                """
                try self.db!.run(sql, note.noteId, note.uuid, note.noteName, note.editedTime, note.editedTime, note.noteText, note.categoryId, 0, 0, note.contentFormat)
                print("Inserted Note with ID \(note.noteId), UUID \(note.uuid)")
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

    func updateNoteUUID(noteId: Int, uuid: String) -> Int {
        var result: Int = -1
        let semaphore = DispatchSemaphore(value: 0)

        concurrentDBQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else {
                semaphore.signal()
                return
            }

            if self.noteExists(searchId: noteId) {
                do {
                    // Use raw SQL to update UUID
                    let sql = "UPDATE notes SET uuid = ? WHERE _id = ?"
                    try self.db!.run(sql, uuid, noteId)
                    print("Updated Note UUID in local DB with ID \(noteId)")
                    result = noteId
                } catch {
                    print("Update failed in updateNoteUUID: \(error)")
                }
            } else {
                print("Can't find Note to update in NoteRecords.updateNoteUUID")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return result
    } //updateNoteUUID

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
