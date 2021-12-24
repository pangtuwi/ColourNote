//
//  Utils.swift
//  FitForm
//
//  Created by Paul Williams on 15/12/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation
import UIKit

// Array difference
// From https://www.hackingwithswift.com/example-code/language/how-to-find-the-difference-between-two-arrays
// Example
// let names1 = ["John", "Paul", "Ringo"]
// let names2 = ["Ringo", "Paul", "George"]
// let difference = names1.difference(from: names2)

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}

extension Date {
    //https://stackoverflow.com/questions/35687411/how-do-i-find-the-beginning-of-the-week-from-an-nsdate
    func getWeekDates() -> (thisWeek:[Date],nextWeek:[Date]) {
        var tuple: (thisWeek:[Date],nextWeek:[Date])
        var arrThisWeek: [Date] = []
        for i in 0..<7 {
            arrThisWeek.append(Calendar.current.date(byAdding: .day, value: i, to: startOfWeek)!)
        }
        var arrNextWeek: [Date] = []
        for i in 1...7 {
            arrNextWeek.append(Calendar.current.date(byAdding: .day, value: i, to: arrThisWeek.last!)!)
        }
        tuple = (thisWeek: arrThisWeek,nextWeek: arrNextWeek)
        return tuple
    }
    
    func getWeekStart() -> Date {
        let i = -1 //week starts on sunday
        return Calendar.current.date(byAdding : .day, value: i, to: startOfWeek)!
    }
    
    func getDaysAgo(unixTime: Double) -> Int {
        let UnixDayStart = midnight.timeIntervalSince1970
        let deltaTime = UnixDayStart - unixTime
        //printMQ("delta time is \(deltaTime)")
        if deltaTime < 0 {
            return 0 }
        else {
            return Int(1 + (deltaTime / (24*60*60)))
        }
    }//getDaysAgo
    
    func getWeeksAgo(unixTime : Double) -> Int {
        let UnixWeekStart = getWeekStart().timeIntervalSince1970
        let deltaTime = UnixWeekStart - unixTime
        //printMQ("delta time is \(deltaTime)")
        if deltaTime < 0 {
            return 0 }
        else {
            return Int(1 + (deltaTime / (7*24*60*60)))
        }
    } //getWeeksAgo
    
    var tomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    
    var midnight: Date {
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }
    
    var startOfWeek: Date {
        let gregorian = Calendar(identifier: .gregorian)
        let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))
        return gregorian.date(byAdding: .day, value: 1, to: sunday!)!
    }
    
    func toDate(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
/*
     Some Tests....
     let weekStart = Date().getWeekStart()
     //printMQ("This week started at \(weekStart)")
     //printMQ("That is Unix time \(weekStart.timeIntervalSince1970)")
     
     var timestamp = 1545699600.0 //Chistmas Day 1 am
     printMQ(" Christmas was \(weekStart.getWeeksAgo(unixTime: timestamp)) weeks ago")
     timestamp = 1546344000.0 //1 Jan 12pm
     printMQ(" New Years day was \(weekStart.getWeeksAgo(unixTime: timestamp)) weeks ago")
     
     timestamp = 1545523201.0 //Sunday 23rd Dec, 1 second past midnight
     printMQ(" Sunday 23rd Dec, 1 second past midnight was \(weekStart.getWeeksAgo(unixTime: timestamp)) weeks ago")
     timestamp = 1545523199.0
     printMQ(" Sat 22rd Dec, 1 second before midnight was \(weekStart.getWeeksAgo(unixTime: timestamp)) weeks ago")
     
*/
    
} //extension Date


func dateString (unixTime : Int) -> String {
    let date = Date(timeIntervalSince1970: Double(unixTime/1000))
    //print (date)
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = TimeZone(abbreviation: "GMT") //Set timezone that you want
    dateFormatter.locale = NSLocale.current
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm" //Specify your format that you want
    let strDate = dateFormatter.string(from: date)
    return strDate
}

func printMQ(_ newStr : String) {
    DispatchQueue.main.async {
        print (newStr)
    }
}

func sessionTimeString (timer_time : Int) -> String {
    var returnString = ""
    if timer_time > 0 {
        let duration: TimeInterval = Double(timer_time)
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second ]
        formatter.zeroFormattingBehavior = [ .pad ]
        
        returnString = formatter.string(from: duration)!
    }
    
    return(returnString)
} //SessionTimeString


struct System {
    static func clearNavigationBar(forBar navBar: UINavigationBar) {
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        navBar.isTranslucent = true
    }
}


func scaleImageToSize(size: CGSize, image: UIImage) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0);
    image.draw(in: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.width * 500 / 1280))
    let imageR = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext();
    return imageR!
}
