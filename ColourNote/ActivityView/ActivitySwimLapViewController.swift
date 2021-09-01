//
//  ActivitySwimLapViewController.swift
//  eFit
//
//  Created by Paul Williams on 26/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import UIKit
import Charts

class ActivitySwimLapViewController: UIViewController {
    
     @IBOutlet weak var hrLaps: BarChartView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
    /*    let myActivity = ActivityRecords.instance.getActivityWithStartTime(startTime: Globals.sharedInstance.activityIDToDisplay) ?? ActivityRecords.instance.getLatestActivity()
        
        if myActivity.sport == Sport.Swimming.rawValue {
            if SwimLapRecords.instance.swimRecordExists(cStartTime: myActivity.startTime) {
                let myActivityData = ActivityData(activity: myActivity)
                displayBarChart (activityData: myActivityData)
            } else {
              //  DataLoader.sharedInstance.loadActivity(whenDone: displayBarChart, Filename: myActivity.filename)
            }
        } */
    } //ViewDidAppear
    
    
    func displayBarChart (activityData: ActivityData) -> Void {
     /*   let mySwimLaps = SwimLapRecords.instance.getSwimRecords(searchStartTime: activityData.sessionStartTime)
        let barDataSet = BarChartDataSet()
        
        for (index, SwimLap) in mySwimLaps.enumerated() {
            let newBar = BarChartDataEntry (x: Double(index), y : SwimLap.secs100m())
            _ = barDataSet.addEntry(newBar)
        }
        
        let barData = BarChartData(dataSets: [barDataSet])
        hrLaps.data = barData
        hrLaps.chartDescription?.text = "Seconds per 100m"
        
       // hrLaps.rightAxis.enabled = true
        hrLaps.chartDescription?.text = "Recorded Sets"
        hrLaps.pinchZoomEnabled = false
        hrLaps.dragXEnabled = false
        //hrChart.highlightPerDragEnabled = true
        
        // y-axis 1
        let llYAxis = ChartLimitLine(limit: 120, label: "120s / 100m")
        llYAxis.lineWidth = 2
        llYAxis.lineDashLengths = [5, 5, 0]
        llYAxis.labelPosition = .rightBottom
        llYAxis.valueFont = .systemFont(ofSize: 10)
        
        let leftAxis = hrLaps.leftAxis
        leftAxis.removeAllLimitLines()
        leftAxis.addLimitLine(llYAxis)
        leftAxis.axisMinimum = 0
        leftAxis.axisMaximum = 240
        leftAxis.yOffset = 0
        
        // x-axis
        let xAxis = hrLaps.xAxis
        xAxis.axisMinimum = 0
       // xAxis.axisMaximum = myFITData.total_timer_time / 60  // Convert to Minutes
        xAxis.yOffset = 0
        xAxis.labelPosition = .bottom
        
        hrLaps.notifyDataSetChanged() */
    }

}
