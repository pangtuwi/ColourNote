//
//  ActivityLineChartViewController.swift
//  eFit
//
//  Created by Paul Williams on 14/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import UIKit
import Charts

class ActivityLineChartViewController: UIViewController {
    
    //var activityStartTime = Int()
    var myActivity = Activity()
    
    @IBOutlet weak var hrChart: LineChartView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if let selectedActivity = ActivityRecords.instance.getActivity(searchActivityId:  Globals.sharedInstance.activityIDToDisplay) ?? ActivityRecords.instance.getLatestActivity() {
                myActivity = selectedActivity
                DataLoader.sharedInstance.loadTrackPoints(whenDone: displayLineChart, ActivityId : myActivity.activityId)
            
        }
    }
    
    
    func displayLineChart (trackPoints : [TrackPoint]) -> Void {
        DispatchQueue.main.async {
            //print ("Drawing line chart")
            //print ("Trackpoints has \(trackPoints.count) values")
            var hrChartEntry = [ChartDataEntry]()
            var altChartEntry = [ChartDataEntry]()
            var powerChartEntry = [ChartDataEntry]()
            
            for tp in trackPoints{
                let newPoint = ChartDataEntry (x:Double(tp.Time-self.myActivity.startTime)/60, y: tp.HR)
                hrChartEntry.append(newPoint)
                
                let newAltPoint = ChartDataEntry (x : Double(tp.Time - self.myActivity.startTime)/60, y: tp.Alt)
                altChartEntry.append(newAltPoint)
                
                let newPwrPoint = ChartDataEntry (x:Double(tp.Time-self.myActivity.startTime)/60, y: tp.Power)
                powerChartEntry.append(newPwrPoint)
            }
            
            let lineHR = LineChartDataSet(entries: hrChartEntry, label: "HeartRate")
            let lineAlt = LineChartDataSet(entries: altChartEntry, label: "Altitude")
            let linePower = LineChartDataSet(entries: powerChartEntry, label: "Power")
            
            lineHR.colors = [NSUIColor.blue]
            lineHR.drawCirclesEnabled = false
            
            lineAlt.colors = [NSUIColor.darkGray]
            lineAlt.drawCirclesEnabled = false
            lineAlt.drawFilledEnabled = true
            lineAlt.fillColor = .darkGray
            lineAlt.axisDependency = .right
            
            linePower.colors = [NSUIColor.red]
            linePower.drawCirclesEnabled = false
            linePower.axisDependency = .right
            
            let data = LineChartData()
            data.addDataSet(lineHR)
            data.addDataSet(lineAlt)
            data.addDataSet(linePower)
            
            self.hrChart.noDataText = "requesting data from Efrt Server"
            self.hrChart.data = data
            self.hrChart.rightAxis.enabled = true
            //self.hrChart.chartDescription?.text = "Garmin Data"
            self.hrChart.pinchZoomEnabled = true
            self.hrChart.dragXEnabled = true  // I think it is true by default anyway?
            self.hrChart.highlightPerDragEnabled = true
            
            // y-axis 1
            //ToDo : Put HR limit line back
          /*  let llYAxis = ChartLimitLine(limit: myActivity.avg_heart_rate(), label: "Average HR")
            llYAxis.lineWidth = 2
            llYAxis.lineDashLengths = [5, 5, 0]
            llYAxis.labelPosition = .rightBottom
            llYAxis.valueFont = .systemFont(ofSize: 10) */
            
            let leftAxis = self.hrChart.leftAxis
            leftAxis.removeAllLimitLines()
            //leftAxis.addLimitLine(llYAxis)
            leftAxis.axisMinimum = 0
            leftAxis.axisMaximum = 200
            leftAxis.yOffset = 0
            
            // y-axis 2
            let rightAxis = self.hrChart.rightAxis
            rightAxis.removeAllLimitLines()
            rightAxis.axisMinimum = 0
            rightAxis.axisMaximum = 800
            rightAxis.yOffset = 0
            
            //Time    Int    1544803615
            //startTime    Int    1544807214
            
            // x-axis
            let xAxis = self.hrChart.xAxis
            xAxis.axisMinimum = 0
            xAxis.axisMaximum = Double(self.myActivity.duration) / 60  // Convert to Minutes
            xAxis.yOffset = 0
            xAxis.labelPosition = .bottom
            
            self.hrChart.notifyDataSetChanged()
        } // dispatch Queue
    }

}
