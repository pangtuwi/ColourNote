//
//  SecondViewController.swift
//  eFit
//
//  Created by Paul Williams on 27/09/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//
// https://www.raywenderlich.com/464-storyboards-tutorial-for-ios-part-1
// https://stackoverflow.com/questions/24475792/how-to-use-pull-to-refresh-in-swift


import UIKit
//import SwiftyDropbox

class TrainingViewController: UITableViewController {
    
    var myActivityData = ActivityData()
    var activities : [Activity] = []
    
    @IBOutlet weak var StatusLabel : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentChangedNotification(_:)),
            name: DataLoaderNotification.contentUpdated,
            object: nil)
        
       // _ = ActivityRecords.instance.deleteActivity(cActivityId : 3923275188)
       //    DataLoader.sharedInstance.deleteFromCache(ActivityId: 3923275188)
        
        refreshControl = UIRefreshControl()
        refreshControl!.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl!.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        
        updateTrainingList()
        
    } //viewDidLoad
    
    
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(true)
    } //viewDidAppear
    
    func updateTrainingList() -> Void {
        activities = ActivityRecords.instance.getActivities()
        activities.sort { $0.startTime > $1.startTime }
        tableView.reloadData()
        StatusLabel.text = "\(activities.count) Activities"
    }
    
    
    @objc func handleRefresh(refreshControl: UIRefreshControl) {
        DispatchQueue.main.async {
            self.StatusLabel.text = "Checking Server for new files..."
        }
        
        DispatchQueue.global(qos: .utility).async {
            DataLoader.sharedInstance.requestSync()
        }
        
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else {
                return
            }
            //DataLoader.sharedInstance.loadFileList(whenDone: self.gotList)
            DataLoader.sharedInstance.loadNewActivityList(whenDone: self.gotList)
            // 2
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {  [weak self] in
                self!.refreshControl!.endRefreshing()
                self!.StatusLabel.text = "\(self!.activities.count) Activities"
            }
        }
    } //handleRefresh
        

    
   // func gotList (hasNewFiles : Bool) -> Void {
    func gotList (newActivityList : [Int]) -> Void {
        //ToDo: Add message for when Server not available
        if newActivityList.count > 0 {
            DispatchQueue.main.async {
                self.StatusLabel.text = "Found \(newActivityList.count) new activities on Server.  Updating..."
            }
            if newActivityList.count <= 10 {
                DataLoader.sharedInstance.downloadEFRTFromList(list: newActivityList)
            } else {
                DataLoader.sharedInstance.downloadMissingEFRT()
            }
         /*   var delaycounter = 0
            var newActivityList2 = newActivityList
            newActivityList2.reverse()
            for newActivityId in newActivityList2 {
                //ToDo : Change this to work off a scheduler with stack?
                //https://gist.github.com/Thomvis/b378f926b6e1a48973f694419ed73aca
                delaycounter += 1
                let newDespatchTime =  DispatchTime.now() + DispatchTimeInterval.seconds(delaycounter/4)
                DispatchQueue.main.asyncAfter(deadline: newDespatchTime) {  [weak self] in
                    DataLoader.sharedInstance.getEfrt(whenDone: self!.gotNewActivity, ActivityId: newActivityId)
                }
 
            } */
        } else {
            DispatchQueue.main.async {
                self.StatusLabel.text = "No new activities on EFRT server"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.StatusLabel.text = "Checking on connect.garmin.com"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.StatusLabel.text = "\(self.activities.count) activities"
            }
        }
    } //gotList
    
    
    func gotNewActivity (efrt : Efrt) -> Void {
        DispatchQueue.main.async {
            self.StatusLabel.text =  "Activity downloaded"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.updateTrainingList()
        }
    } //gotNewActivity
    

}  //TrainingViewController


extension TrainingViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activities.count
    }
    
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityCell", for: indexPath)
        // ToDo : Fix occasional Fatal error : Index out of range
        // print ("Training View Table View loading \(indexPath.row) of \(activities.count)")
        if (indexPath.row <= activities.count) {
            let activity = activities[indexPath.row]
            if (activity.tss == -1) {
                cell.textLabel?.text = "...pending download"
            } else {
                cell.textLabel?.text = "\(activity.tss) TSS - \(activity.activityName)"
            }
            cell.detailTextLabel?.text = "\(activity.activityId) - \(activity.agoString())"
            if activity.ignore {
                cell.textLabel?.textColor = Globals.EFRT_LTGREY
            } else {
                cell.textLabel?.textColor = Globals.EFRT_DKGREY
            }
        } else {
            cell.textLabel?.text = "Loading..."
            cell.detailTextLabel?.text = ""
        }
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Globals.sharedInstance.activityIDToDisplay = activities[indexPath.row].activityId
        tabBarController!.selectedIndex = 3
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        //ACTION to IGNORE an Activity
        let ignoreAction = UIContextualAction(style: .normal, title: "ignore",
                                              handler: { (action, view, completionHandler) in
            if (self.activities[indexPath.row].ignore == false) {
                _ = ActivityRecords.instance.setActivityIgnore(changedActivityId: self.activities[indexPath.row].activityId, ignore: true)
                self.activities[indexPath.row].ignore = true
            } else {
                _ = ActivityRecords.instance.setActivityIgnore(changedActivityId: self.activities[indexPath.row].activityId, ignore: false)
                self.activities[indexPath.row].ignore = false
            }
            NotificationCenter.default.post(name: DataLoaderNotification.contentUpdated, object: nil)
            self.tableView.reloadData()
            completionHandler(true)
                        
        })
        ignoreAction.image = UIImage(named: "medal")
        ignoreAction.backgroundColor = Globals.EFRT_ORANGE
        
        //Action to re-DOWNLOAD an Activity
        let downloadAction = UIContextualAction(style: .normal, title: "download",
                                              handler: { (action, view, completionHandler) in
            DataLoader.sharedInstance.deleteFromCache(ActivityId: self.activities[indexPath.row].activityId )
            DataLoader.sharedInstance.getEfrt(whenDone: self.gotNewActivity, ActivityId: self.activities[indexPath.row].activityId )
            NotificationCenter.default.post(name: DataLoaderNotification.contentUpdated, object: nil)
            self.tableView.reloadData()
            completionHandler(true)
        })
        downloadAction.image = UIImage(named: "download")
        downloadAction.backgroundColor = Globals.EFRT_BLUE
        
        let configuration = UISwipeActionsConfiguration(actions: [ignoreAction, downloadAction])
        return configuration
    }
    
}

// MARK: - Notification handlers
extension TrainingViewController {
    @objc func contentChangedNotification(_ notification: Notification!) {
        updateTrainingList()
        let app = UIApplication.shared
        app.applicationIconBadgeNumber = 0
       // print ("Content Change notification recieved in TrainingViewController")
    }
}



