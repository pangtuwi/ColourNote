//
//  HomeLastActivityViewController.swift
//  eFrt
//
//  Created by Paul Williams on 01/01/2019.
//  Copyright © 2019 Paul Williams. All rights reserved.
//

import UIKit

class AnalysisDetailViewController: UIViewController, UITableViewDataSource {

    @IBOutlet weak var tableView1 : UITableView!
    @IBOutlet weak var tableView2 : UITableView!
    
    struct ActivityDetail : Codable {
        let description : String
        let value : String
        init(descr : String, val : String){
            description = descr
            value = val
        }
    }
    
    private var displayedActivityID : Int = 0
    private var tableData : [ActivityDetail] = []
    private var tableEfrtData : [ActivityDetail] = []
    
    var lastActivityID = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentChangedNotification(_:)),
            name: DataLoaderNotification.contentUpdated,
            object: nil)
        
        tableView1.dataSource = self
        tableView2.dataSource = self
    } //viewDidLoad
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if (lastActivityID != Globals.sharedInstance.activityIDToDisplay) {
            tableData.removeAll()
            tableEfrtData.removeAll()
            tableView1.reloadData()
            tableView2.reloadData()
            lastActivityID = Globals.sharedInstance.activityIDToDisplay
        }
        
        if let activity = ActivityRecords.instance.getActivity(searchActivityId:
            Globals.sharedInstance.activityIDToDisplay) ?? ActivityRecords.instance.getLatestActivity() {
            displayData(activity: activity)
        }
    } //viewDidAppear

    
    func displayData (activity : Activity) {
        // Activity data from Activity Record
        //var activity : Activity
            if displayedActivityID != activity.activityId {
                displayedActivityID = activity.activityId
                tableData.removeAll()
                let AD0 = ActivityDetail (descr: "activity type", val: activity.sportString())
                tableData.append(AD0)
                let AD1 = ActivityDetail (descr: "date", val: activity.agoString())
                tableData.append(AD1)
                let AD2 = ActivityDetail (descr: "duration", val: sessionTimeString(timer_time: activity.duration))
                tableData.append(AD2)
                let AD3 = ActivityDetail (descr: "distance", val: "\(activity.distance)")
                tableData.append(AD3)
                let AD4 = ActivityDetail (descr: "TSS", val: "\(activity.tss)")
                tableData.append(AD4)
                tableView1.reloadData()
                
                //Efrt Data from Efrt.
                DataLoader.sharedInstance.getEfrt(whenDone: displayEfrtData, ActivityId : activity.activityId)
            }
        
    }//displayData
    
    
    func displayEfrtData (efrt : Efrt   ) -> Void {
        tableEfrtData.removeAll()
        let AD0 = ActivityDetail (descr: "average heart rate", val: "\(efrt.avgHR)")
        tableEfrtData.append(AD0)
        let AD1 = ActivityDetail (descr: "maximum heart rate", val: "\(Int(efrt.maxHR))")
        tableEfrtData.append(AD1)
        let AD2 = ActivityDetail (descr: "average power", val: "\(Int(efrt.avgPower))")
        tableEfrtData.append(AD2)
        let AD3 = ActivityDetail (descr: "maximum power", val: "\(Int(efrt.maxPower))")
        tableEfrtData.append(AD3)
        let AD4 = ActivityDetail (descr: "average cadence", val: "\(efrt.avgCadence)")
        tableEfrtData.append(AD4)
        
        DispatchQueue.main.async { self.tableView2.reloadData() }
    } //displayEfrtData
    
    
    // - - - - - - - - - - - TableView Creation Functions - - - - - - - - - - -
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    } //viewDidLoad
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if tableView == self.tableView1 {
            cell = tableView.dequeueReusableCell(withIdentifier: "LastActivityCell1ReuseIdentifier")!
            if (tableData.count > indexPath.row) {
                cell.detailTextLabel?.text = tableData[indexPath.row].description
                cell.textLabel?.text = tableData[indexPath.row].value
            } else {
                cell.detailTextLabel?.text = ""
                cell.textLabel?.text = ""
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "LastActivityCell2ReuseIdentifier")!
            if (tableEfrtData.count > indexPath.row) {
                cell.detailTextLabel?.text = tableEfrtData[indexPath.row].description
                cell.textLabel?.text = tableEfrtData[indexPath.row].value
            } else {
                cell.textLabel?.text = ""
                cell.detailTextLabel?.text = ""
            }
        }
        return cell
    } //cellForRowAt

}

// MARK: - Notification handlers
extension AnalysisDetailViewController {
    @objc func contentChangedNotification(_ notification: Notification!) {
       // displayData()
    }
}
