//
//  FitForm
//
//  Created by Paul Williams on 02/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//
// JSON POST https://stackoverflow.com/questions/26364914/http-request-in-swift-with-post-method
// alternate https://medium.com/@sdrzn/networking-and-persistence-with-json-in-swift-4-part-2-e4f35a606141
// to avoid errors "This application is modifying the autolayout engine... " https://stackoverflow.com/questions/28302019/getting-a-this-application-is-modifying-the-autolayout-engine-from-a-background
// https://www.raywenderlich.com/5370-grand-central-dispatch-tutorial-for-swift-4-part-1-2

// URL Error Codes
// https://developer.apple.com/documentation/foundation/1508628-url_loading_system_error_codes
// -1001 = Timeout
// -1005 = Network Connection Lost

import Foundation

struct DataLoaderNotification {
    // Notification when new instances are added
    static let contentAdded = Notification.Name("com.efrt.DataLoaderContentAdded")
    // Notification when content updates (i.e. Download finishes)
    static let contentUpdated = Notification.Name("com.efrt.DataLoaderContentUpdated")
}


var activities = [ActivityListing]()

struct EFRTServerResponse : Codable {
    let result : Bool
    let message : String
}

class DataLoader {
    
    static let sharedInstance = DataLoader()
    
    var currentTrackPointActivityId = Int()
 //   var trackPoints = [TrackPoint]()
    
   // var currentEfrtActivityId = Int()
    var efrt = Efrt()
    
    var fileList : [String]
    var newActivityList = [Int]()
    
    //Caching of EFRT and Trackpoint Data
    var EFRTCacheURL: URL?
    var TPCacheURL: URL?
    
    init () {
        fileList = []
    }
    
    
    func userExists(whenDone: @escaping (_ inDB : Bool, _ message : String) -> Void) {
       
        printMQ ("checking EFRT server for User")
        let parameters = UserCredentials.init()
        
        //create the url with URL
        let url = URLs.eFrtServerHasUserURL()
        
        //create the session object
        let session = URLSession.shared
        
        //now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST
        
        // Now let's encode out Post struct into JSON data...
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(parameters)
            // ... and set our request's HTTP body
            request.httpBody = jsonData
            let requestJSONString = String(data: request.httpBody!, encoding: .utf8) ?? "no body data"
            printMQ("sending jsonData: \(requestJSONString)")
            
        } catch {
            printMQ("Error Encoding JSON in  userExists.  Error is : \(error)" )
            return
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        //create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            if error != nil {
                whenDone(false, "Error contacting EFRT server - \(error!.localizedDescription)")
            }
            
            do {
                let decoder = JSONDecoder()
                if let data = data {
                    let serverResponse = try decoder.decode(EFRTServerResponse.self, from: data)
                    if serverResponse.result == true {
                        whenDone(true, "User found in EFRT user database")
                    } else {
                        whenDone(false, serverResponse.message)
                    }
                } else {
                    whenDone(false, "No response from EFRT Server")
                }
                
            } catch let jsonError {
                print(jsonError)
                whenDone(false, "Got an unexpected response from the EFRT Server")
            }
            
            
        })
        task.resume()
    } //userExists
    

    func addUser () {
        //printMQ ("Adding User to EFRT Server")
        
        let parameters = UserCredentials.init()
        
        //create the url with URL
        let url = URLs.eFrtServerAddUserURL()
        
        //create the session object
        let session = URLSession.shared
        
        //now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST
        
        // Now let's encode out Post struct into JSON data...
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(parameters)
            // ... and set our request's HTTP body
            request.httpBody = jsonData
          /*  DispatchQueue.main.async { // run Print Commands in main queue.
                print("jsonData: ", String(data: request.httpBody!, encoding: .utf8) ?? "no body data")
            } */
        } catch {
            printMQ("Error Encoding JSON in Dataloader.loadactivity.  Error is : ")
            printMQ(error.localizedDescription)
            return
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        //create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            guard error == nil else {
                printMQ("got error != nil in addNewUser")
                return
            }
            
            guard let _ = data else {
                printMQ("got reply for addNewUser")
                return
            }
            
        })
        task.resume()
    } //addNewUser
    

    func sendNewDeviceToken () {
        printMQ ("Sending new DeviceToken to server")
        
        let parameters = DeviceToken.init()
        
        //create the url with URL
        let url = URLs.eFrtServerDeviceTokenURL()
        
        //create the session object
        let session = URLSession.shared
        
        //now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST
        
        // Now let's encode out Post struct into JSON data...
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(parameters)
            // ... and set our request's HTTP body
            request.httpBody = jsonData
           /* DispatchQueue.main.async { // run Print Commands in main queue.
                    print("jsonData: ", String(data: request.httpBody!, encoding: .utf8) ?? "no body data")
            } */
        } catch {
            print("Error Encoding JSON in Dataloader.loadactivity.  Error is : " ,error)
            return
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        //create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            guard error == nil else {
                printMQ("got error != nil in sendNewDeviceToken")
                return
            }
            
            guard let _ = data else {
                printMQ("got reply for sendNewDeviceToken")
                return
            }
        
        })
        task.resume()
    } //sendNewDeviceToken
    
    func updatePassword () {
        //printMQ ("Sending updated password to server")
        
        let parameters = UserCredentials.init()
        
        //create the url with URL
        let url = URLs.eFrtServerUpdatePasswordURL()
        
        //create the session object
        let session = URLSession.shared
        
        //now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST
        
        // Now let's encode out Post struct into JSON data...
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(parameters)
            // ... and set our request's HTTP body
            request.httpBody = jsonData
           /* DispatchQueue.main.async { // run Print Commands in main queue.
                print("jsonData: ", String(data: request.httpBody!, encoding: .utf8) ?? "no body data")
            } */
        } catch {
            print("Error Encoding JSON in Dataloader.loadactivity.  Error is : " ,error)
            return
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        //create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            guard error == nil else {
                printMQ("got error != nil in sendNewDeviceToken")
                return
            }
            
            guard let _ = data else {
                printMQ("got reply for sendNewDeviceToken")
                return
            }
            
        })
        task.resume()
    } //sendNewDeviceToken
    
    func testConnection2(whenDone: @escaping (_ connectionOK : Bool, _ message : String) -> Void) {
        printMQ ("testing connection to server (with Password)")
        
        let parameters = UserCredentials.init()
        
        //create the url with URL
        let url = URLs.eFrtServerTestConnectionURL()
        
        //create the session object
        let session = URLSession.shared
        
        //now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST
        
        // Now let's encode out Post struct into JSON data...
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(parameters)
            // ... and set our request's HTTP body
            request.httpBody = jsonData
            DispatchQueue.main.async { // run Print Commands in main queue.
                print("jsonData: ", String(data: request.httpBody!, encoding: .utf8) ?? "no body data")
            }
        } catch {
            print("Error Encoding JSON in testConnection2.  Error is : " ,error)
            return
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        //create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            if error != nil {
                whenDone(false, "Error contacting EFRT server - \(error!.localizedDescription)")
            }
            
            do {
                let decoder = JSONDecoder()
                if let data = data {
                    let serverResponse = try decoder.decode(EFRTServerResponse.self, from: data)
                    if serverResponse.result == true {
                        whenDone(true, "Connection to Garmin Server OK")
                    } else {
                        whenDone(false, serverResponse.message)
                    }
                } else {
                    whenDone(false, "No response from EFRT Server")
                }
                
            } catch let jsonError {
                print(jsonError)
                whenDone(false, "Got an unexpected response from the EFRT Server")
            }
 
            
        })
        task.resume()
    }
    
    func testConnection(whenDone: @escaping (_ connectionOK : Bool, _ message : String) -> Void) {
        //printMQ ("testing connection to server")
        URLSession.shared.dataTask(with: URLs.eFrtServerTestConnectionURL()) { (data, response, error) in
            if error != nil {
                whenDone(false, "Error contacting EFRT server - \(error!.localizedDescription)")
            }
            
            do {
                let decoder = JSONDecoder()
                if let data = data {
                    let serverResponse = try decoder.decode(EFRTServerResponse.self, from: data)
                    if serverResponse.result == true {
                        whenDone(true, "Connection to Garmin Server OK")
                    } else {
                        whenDone(false, serverResponse.message)
                    }
                } else {
                    whenDone(false, "No response from EFRT Server")
                }
             
             } catch let jsonError {
                print(jsonError)
                whenDone(false, "Got an unexpected response from the EFRT Server")
             }
  
        }.resume()
    } //testConnection
    
    
    func loadNewActivityList(whenDone: @escaping (_ list : [Int]) -> Void) {
        printMQ ("loading new activity list from server : \(URLs.eFrtServerListURL())")
        URLSession.shared.dataTask(with: URLs.eFrtServerListURL()) { (data, response, error) in
            if error != nil {
                print ("SERVER ERROR EFRT : \(error!.localizedDescription)")
            }
            
            guard let data = data else { return }
            //Implement JSON decoding and parsing
            
            do {
                let decoder = JSONDecoder()
                activities = try decoder.decode(Array<ActivityListing>.self, from: data)
                DispatchQueue.main.async {
                    print ("got Activity list from EFRT Server with \(activities.count) activities")
                }
                self.newActivityList.removeAll()
                for activity in activities  {
                    //ToDo: rewrite this so that it gets an array of current activities and does a difference
                    if !ActivityRecords.instance.activityExists(searchId : activity.activityId) {
                        //create temporary entry in database
                        let _ = ActivityRecords.instance.addTempActivity(newActivity: activity)
                        self.newActivityList.append(activity.activityId)
                        
                        //print ("Found New Activity : added \(activity.activityId) to list")
                    } else {
                        //print ("...already in database = \(activity.activityId)")
                    }
                }
                if self.newActivityList.count == 0 {
                    whenDone ([])
                } else {
                    whenDone(self.newActivityList)
                }
                
            } catch let jsonError {
                print(jsonError)
            }
            }.resume()
        
    } //loadnewActivityList
    
    func notifyDownloadedActivity(efrt : Efrt){
        DispatchQueue.main.async {
            //print("Sending contentUpdated Notification")
            NotificationCenter.default.post(name: DataLoaderNotification.contentUpdated, object: nil)
        }
    } //notifyDownloadedActivity
    
    
    func downloadEFRTFromList(list : [Int]) {
        //Process list of of Activities that need updating
        var delaycounter = 0
        var activityList = list
        activityList.sort()
        activityList.reverse()
        for newActivityId in activityList {
            delaycounter += 1  // 1 second between calls
            let newDespatchTime =  DispatchTime.now() + DispatchTimeInterval.seconds(delaycounter)
            DispatchQueue.main.asyncAfter(deadline: newDespatchTime) {  [weak self] in
                //getEfrt(whenDone: self!.gotNewActivity, ActivityId: newActivityId)
                self?.getEfrt(whenDone: self!.notifyDownloadedActivity, ActivityId: newActivityId)
            }
        }
    } //downloadEFRTFromList
    
    
    func downloadMissingEFRT(){
        //starts download of missing EFRT data
        //Recursive, calls self every 60 seconds until list is zero
        //10 at a time
        var workingList = [Int]()
        var listWithoutTSS = ActivityRecords.instance.getListOfActivitiesWithoutTSS()
        if (listWithoutTSS.count == 0) {
            return
        } else {
            listWithoutTSS.sort()
            listWithoutTSS.reverse()
            workingList = Array(listWithoutTSS.prefix(10))  //Only 10 at a time
            downloadEFRTFromList(list: workingList)
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                self.downloadMissingEFRT()
            }
        }
    } //downloadMissingEFRT
    
    
    func clearCache(){
        //Never Tested, NeVer Used
        // From https://stackoverflow.com/questions/39004124/what-are-the-best-practice-for-clearing-cache-directory-in-ios/39012838
        let cacheURL =  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let fileManager = FileManager.default
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory( at: cacheURL, includingPropertiesForKeys: nil, options: [])
            for file in directoryContents {
                do {
                    try fileManager.removeItem(at: file)
                }
                catch let error as NSError {
                    debugPrint("Ooops! Something went wrong: \(error)")
                }
                
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    } //clearCache
    
    
    func deleteFromCache(ActivityId : Int){
        // Modified From https://stackoverflow.com/questions/39004124/what-are-the-best-practice-for-clearing-cache-directory-in-ios/39012838
        let cacheURL =  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let fileManager = FileManager.default
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory( at: cacheURL, includingPropertiesForKeys: nil, options: [])
            for file in directoryContents {
                do {
                    if file.lastPathComponent == "efrt-\(ActivityId).json" {
                    try fileManager.removeItem(at: file)
                    }
                }
                catch let error as NSError {
                    debugPrint("Ooops! Something went wrong: \(error)")
                }
                
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }  //deleteFromCache
    
    
    func getEfrt (whenDone: @escaping (_ efrt : Efrt) -> Void, ActivityId : Int)  {
    //func getEfrt (whenDone: @escaping () -> Void, ActivityId : Int)  {
        //printMQ ("getting Efrt for \(ActivityId)")
        var hasCached = false
        var newEfrt = Efrt()
        let parameters = UserConfig.init()
        
        // Create Cache URL
        if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            self.EFRTCacheURL = cacheURL.appendingPathComponent("efrt-\(ActivityId).json")
        }
        //Check if exists in Cache
        if let userCacheURL = self.EFRTCacheURL {
            printMQ ("Cache file found for \(ActivityId)")
         //   self.userCacheQueue.addOperation() {
                let jsonDecoder = JSONDecoder()
                
                if let data = try? Data(contentsOf: userCacheURL) {
                   // self.users = (try? jsonDecoder.decode([User].self, from: data)) ?? []
                   // let decoder = JSONDecoder()
                    newEfrt = (try! jsonDecoder.decode(Efrt.self, from: data))
                    if newEfrt.duration != 0 {
                        hasCached = true
                        printMQ ("Got EFRT from cache for  \(ActivityId)")
                        whenDone(newEfrt)
                        //whenDone()
                    } else {
                        printMQ ("could not decode cache for  \(ActivityId)")
                        _ = ActivityRecords.instance.setActivityIgnore(changedActivityId: ActivityId, ignore: true)
                        deleteFromCache(ActivityId: ActivityId)
                    }
                    
                } else {
                    //printMQ ("No cache for  \(ActivityId)")
            }
       //     }
        }
        if !hasCached {
        //create the url with URL
        let url = URLs.eFrtServerEfrtURL(GarminActivityID: ActivityId)
    
        //create the session object
        let session = URLSession.shared
        
        //now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST
        
        // Now let's encode out Post struct into JSON data...
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(parameters)
            // ... and set our request's HTTP body
            request.httpBody = jsonData
        } catch {
            print("Error Encoding JSON in Dataloader.loadactivity.  Error is : " ,error)
            return
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        //create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            guard error == nil else {
                printMQ("Error in DataLoader.GetEfrt while loading \(ActivityId) : Error was \(error?.localizedDescription ?? "No Error Description")")
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                //create json object from data
                //dont need this, but checks that result is JSON
                //ToDO : Change this to check for data / server errors
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    
                    let JSONCode = json["code"] as? String ?? ""
                    if (JSONCode == "NotFound") {
                        printMQ ("got NotFound from server for activity \(ActivityId)")
                        whenDone(newEfrt)
                        //whenDone()
                    }
                        
                    let decoder = JSONDecoder()
                    newEfrt = try decoder.decode(Efrt.self, from: data)
                    _ = ActivityRecords.instance.updateActivity(changedActivityId: ActivityId, efrt: newEfrt)
                    ActivityRecords.instance.setActivityIgnore(changedActivityId: ActivityId, ignore: false)
                    // Write the response to the cache
                    if let userCacheURL = self.EFRTCacheURL {
                        try? data.write(to: userCacheURL)
                        //printMQ ("Wrote EFRT to cache for  \(ActivityId)")
                    }
                    
                    whenDone(newEfrt)
                    //whenDone()
                    
                } else {
                    printMQ ("could not deserialse JSON in DataLoader.getEfrt")
                    return
                }
                
            } catch let error {
                _ = ActivityRecords.instance.setActivityIgnore(changedActivityId: ActivityId, ignore: true)
                printMQ("Error in DataLoader.GetEfrt -requested \(ActivityId), got \(error.localizedDescription)")
                printMQ("Set \(ActivityId) to IGNORE")
                
            }
        })
        task.resume()
        }
    } //getEfrt
    
    
 /* OLD Function returning Bool
    func loadEfrt (whenDone: @escaping (_ success : Bool) -> Void, ActivityId : Int)  {
        printMQ ("Requesting activity Efrt for \(ActivityId) from server")
        
        let parameters = UserConfig.init()
        
        //create the url with URL
        let url = URLs.eFrtServerEfrtURL(GarminActivityID: ActivityId)
        
        //create the session object
        let session = URLSession.shared
        
        //now create the URLRequest object using the url object
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST
        
        // Now let's encode out Post struct into JSON data...
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(parameters)
            // ... and set our request's HTTP body
            request.httpBody = jsonData
            DispatchQueue.main.async { // run Print Commands in main queue.
                //    print("jsonData: ", String(data: request.httpBody!, encoding: .utf8) ?? "no body data")
            }
        } catch {
            print("Error Encoding JSON in Dataloader.loadactivity.  Error is : " ,error)
            return
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        //create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            guard error == nil else {
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                //create json object from data
                //dont need this, but checks that result is JSON
                //ToDO : Change this to check for data / server errors
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    
                    let JSONCode = json["code"] as? String ?? ""
                    if (JSONCode == "NotFound") {
                        printMQ ("got NotFound from server for activity \(ActivityId)")
                        whenDone(false)
                    }
                    let decoder = JSONDecoder()
                    self.efrt = try decoder.decode(Efrt.self, from: data)
                    _ = ActivityRecords.instance.updateActivity(changedActivityId: ActivityId, efrt: self.efrt)
                    DispatchQueue.main.async {
                        //print("Sending contentUpdated Notification")
                        NotificationCenter.default.post(name: DataLoaderNotification.contentUpdated, object: nil)
                    }
                    
                    whenDone(true)
                    
                    } else {
                        printMQ ("could not deserialse JSON for activity \(ActivityId) in DataLoader.loadEfrt")
                        return
                    }
                    
                
                
            } catch let error {
                print(error.localizedDescription)
            }
        })
        task.resume()
    } //loadEfrt
 */
    
    
    func loadTrackPoints (whenDone: @escaping (_ tp : [TrackPoint]) -> Void, ActivityId : Int)  {
        var trackPoints = [TrackPoint]()
        var hasCached = false
        
        // Create Cache URL
        if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            self.TPCacheURL = cacheURL.appendingPathComponent("tp-\(ActivityId).json")
        }
        //Check if exists in Cache
        if let userCacheURL = self.TPCacheURL {
            //   self.userCacheQueue.addOperation() {
            let jsonDecoder = JSONDecoder()
            
            if let data = try? Data(contentsOf: userCacheURL) {
                if let trackPoints = (try? jsonDecoder.decode(Array<TrackPoint>.self, from: data)){
                    hasCached = true
                    //printMQ ("Got TRACKPOINTS from cache for  \(ActivityId)")
                    whenDone(trackPoints)
                } else {
                   // printMQ ("could not decode trackpoint cache for  \(ActivityId)")
                }
                
            } else {
                //printMQ ("No trackpoint cache for  \(ActivityId)")
            }
        }
        if !hasCached {
            //printMQ ("Requesting trackpoints for \(ActivityId) from server")
            
            let url = URLs.eFrtServerTrackPointsURL(GarminActivityID : ActivityId, freq: 5)
            let session = URLSession.shared
            
            //now create the URLRequest object using the url object
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            
            //create dataTask using the session object to send data to the server
            let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
                
                guard error == nil else {
                    printMQ("Error <! nil in DataLoader.LoadTrackPoints")
                    printMQ("\(String(describing: error))")
                    return
                }
                
                guard let data = data else {
                    printMQ("data != data in  DataLoader.LoadTrackPoints")
                    return
                }
                
                do {
                    
                    // Write the response to the cache
                    if let userCacheURL = self.TPCacheURL {
                        try? data.write(to: userCacheURL)
                        //printMQ ("Wrote TRACKPOINTS to cache for  \(ActivityId)")
                    }
                    
                    let decoder = JSONDecoder()
                    trackPoints = try decoder.decode(Array<TrackPoint>.self, from: data)
                  //  self.currentTrackPointActivityId = ActivityId
                    whenDone(trackPoints)
                    
                } catch let error {
                    printMQ("Error in JSONDecoder do loop in DataLoader.LoadTrackPoints")
                    printMQ("\(error.localizedDescription)")
                }
            })
            task.resume()
        } // end If Server Call
    } //loadTrackPoints
    
    
    func requestSync() {
        //printMQ ("requesting Sync from EfrtServer")
        URLSession.shared.dataTask(with: URLs.eFrtServerSyncURL()) { (data, response, error) in
            if error != nil {
                print ("SERVER ERROR EFRT : \(error!.localizedDescription)")
                //ToDo : Send message back in the event of SERVER ERROR EFRT : Could not connect to the server.
            }
            
            guard data != nil else { return }

            }.resume()
        
    } //requestSync
    
}
