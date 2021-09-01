//
//  FirstViewController.swift
//  eFit
//
//  Created by Paul Williams on 27/09/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import UIKit
//

class ActivityViewController: UIViewController {


    @IBOutlet weak var dateLabel : UILabel!
    @IBOutlet weak var sportLabel : UILabel!
    @IBOutlet weak var TSSLabel : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    } //viewDidLoad

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
       // var activity : Activity
        
        if let activity = ActivityRecords.instance.getActivity(searchActivityId:  Globals.sharedInstance.activityIDToDisplay) ?? ActivityRecords.instance.getLatestActivity() {
            dateLabel.text = "\(activity.activityName)"
            sportLabel.text = "\(activity.sportString())  |  \(sessionTimeString(timer_time: activity.duration))  |  \(activity.agoString())"
            TSSLabel.text = "\(activity.tss) TSS"
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Changed Tab View - clear activityIDToDisplay
        Globals.sharedInstance.activityIDToDisplay = 0
    }
}

