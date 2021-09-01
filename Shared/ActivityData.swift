//
//  FITData.swift
//  FitForm
//
//  Created by Paul Williams on 08/08/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

// hrTSS  https://www.trainingpeaks.com/blog/estimating-training-stress-score-tss/

import Foundation
//import FitDataProtocol
//import TrackKit

let filterT = [5, 30, 60, 300, 1200]  //5s power...20min power
let FTP = 298.0
//ToTO : FTP etc. as user changed variables (store in Globals?)

//let currFitData = FITData ()

class ActivityData {
    var dataOK : Bool = false
    
    var sessionStartTime : Int = 0   //timestamp of start of session

    var activityId : Int
    var activityType : String = "-"      //i.e. cycling
    var activitySubType : String = "-"   //i.e. mountain
    var activityTypeInt : Int;
 
    var total_timer_time : Double
    private var total_heart_rate : Double
    var max_heart_rate : Double
    var total_power : Double
    var max_avg_power : [Int : Double]
    
    var hr : [Double]
    var power : [Double]
    
    var zones = Zones()
    var hrStats : TrackStats?
    var powerStats : TrackStats?
    
    var powerTSS : Double
    var hrTSS : Double
    var swimTSS : Double

    var efrtActivity : EfrtActivity?
    
    init() {
        self.activityId = 0
        self.activityType = "No Activity Loaded"
        self.activitySubType = "-"
        self.activityTypeInt = 0
        
        //ToTo: Convert all to same ActivityType
        
        self.total_timer_time = 0
        self.total_heart_rate = 0
        self.max_heart_rate = 0
        self.total_power = 0
        self.max_avg_power = [:]
        
        self.hr = []
        self.power = []
        self.powerTSS = 0
        self.hrTSS = 0
        self.swimTSS = 0
    } //init ()
    
    
    
    init (JSON: Data) {
        self.activityId = 0
        
        self.activityType = "No Activity Loaded"
        self.activitySubType = "-"
        self.activityTypeInt = 0
        
        //ToTo: Convert all to same ActivityType
        
        self.total_timer_time = 0
        self.total_heart_rate = 0
        self.max_heart_rate = 0
        self.total_power = 0
        self.max_avg_power = [:]
 
        self.hr = []
        self.power = []
        self.powerTSS = 0
        self.hrTSS = 0
        self.swimTSS = 0
        
       // var efrtActivity : EfrtActivity
        
        do {
            let decoder = JSONDecoder()
            efrtActivity = try decoder.decode(EfrtActivity.self, from: JSON)
            
            if efrtActivity!.activityId > 0 {
                DispatchQueue.main.async {
                    print ("Able to decode \(self.efrtActivity!.activityId)")
                }
                self.activityId = efrtActivity?.activityId ?? 0
                self.activityTypeInt = efrtActivity?.garminData.activityType.typeId ?? 0
                if (self.activityTypeInt == 27) {self.activityTypeInt = 4}  //Garmin TCX error - sometimes 27
                self.hrTSS = efrtActivity?.efrt.hrTSS ?? 0
                self.swimTSS = efrtActivity?.efrt.swimTSS ?? 0
                self.total_timer_time = Double(efrtActivity?.garminData.duration ?? 0)
                self.sessionStartTime = efrtActivity?.activityStartTime ?? 0
            
                
                dataOK = true
            } else {  //file has no activities
                dataOK = false
            }
        } catch let error {
            DispatchQueue.main.async {
                print("Error Decoding Activity JSON in ActivityData.swift for activityId : \(self.activityId)")
                print(error)
            }
        }
    } //init (Data)
    
    
    func addLapToSessionTotalTimerTime (newLapTime : Double) {
        self.total_timer_time += newLapTime
    }
    
    
    func getActivityTypeFromFilename (Filename : String) -> Int {
        if Filename.contains("Running") { return 1 }
            else if Filename.contains("MtnBiking") { return 3 }
            else if Filename.contains("Cycling") { return 2 }
            else if Filename.contains("Swimming") { return 4 }
        else { return 0 }
    } //getActivityTypeFromFilename
    
    
    func getActivityTypeFromTCX (Sport : String) -> Int {
        if (Sport == "Biking") {return 2}
        else if (Sport == "Running") {return 1}
        else if (Sport == "Other") {return 4}
        else {
            return 0
        }
    } //getActivityTypeFromTCX
    
    
    func sessionStartDateTimeString () -> String {
        if sessionStartTime == 0 {
            return ""
        } else {
            let date = Date(timeIntervalSince1970: TimeInterval(sessionStartTime))
            let dayTimePeriodFormatter = DateFormatter()
            dayTimePeriodFormatter.dateFormat = "MMM dd YYYY hh:mm a"
            return dayTimePeriodFormatter.string(from: date)
        }
    } //SessionStartateTimeString
    
    
    func sessionTimeString () -> String {
        var returnString = ""
        if total_timer_time > 0 {
            let duration: TimeInterval = total_timer_time // 2 minutes, 30 seconds
            
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .positional
            formatter.allowedUnits = [.hour, .minute, .second ]
            formatter.zeroFormattingBehavior = [ .pad ]
            
            returnString = formatter.string(from: duration)!
            }
        
        return(returnString)
    } //SessionTimeString
    
  
}
