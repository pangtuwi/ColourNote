//
//  ActivityBarChartViewController.swift
//  eFit
//
//  Created by Paul Williams on 15/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//
// https://github.com/danielgindi/Charts

import UIKit
import Charts

class ActivityHRBarChartViewController: UIViewController {

    var myActivity = Activity()
    var myEfrt = Efrt()
    var lastActivityID = 0
    
    @IBOutlet weak var hrHistogram : BarChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Globals.EFRT_BKGREY
        self.hrHistogram.noDataText = "fetching chart data"
    } //viewDidLoad
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if (lastActivityID != Globals.sharedInstance.activityIDToDisplay) {
            hrHistogram.clear()
            lastActivityID = Globals.sharedInstance.activityIDToDisplay
        }
        
        if let myActivity = ActivityRecords.instance.getActivity(searchActivityId:  Globals.sharedInstance.activityIDToDisplay) ?? ActivityRecords.instance.getLatestActivity() {
            DataLoader.sharedInstance.getEfrt(whenDone: displayBarChart, ActivityId : myActivity.activityId)
        }
    } //viewDidAppear
    
    
    func displayBarChart (efrt : Efrt   ) -> Void {
        DispatchQueue.main.async {
            let barDataSet = BarChartDataSet()
            
            self.myEfrt = efrt
            
            var i  = 0
            for zone in efrt.hrHist {
                i = i + 1
                let newBar = BarChartDataEntry (x: Double(i), y : Double(zone.count))
            
                _ = barDataSet.addEntry(newBar)
            }
        
            barDataSet.setColor(UIColor(red: 0x0F/255, green: 0x90/255, blue: 0xCB/255, alpha: 1))
            barDataSet.drawValuesEnabled = false
            //barDataSet.setColor(0x0F90CB)
            
            
            let barData = BarChartData(dataSets: [barDataSet])
           // barData.barWidth = 10
            
            self.hrHistogram.data = barData
            //hrHistogram.chartDescription?.text = "Heart Rate Distribution"
            self.hrHistogram.rightAxis.enabled = false
            self.hrHistogram.pinchZoomEnabled = true
            self.hrHistogram.dragXEnabled = true
            self.hrHistogram.drawBarShadowEnabled = false
            //hrHistogram.drawValueAboveBarEnabled = false
            //hrChart.highlightPerDragEnabled = true
            
            let leftAxis = self.hrHistogram.leftAxis
            // leftAxis.axisMinimum = 0
            // leftAxis.axisMaximum = 240
            leftAxis.axisMinimum = 0
            leftAxis.yOffset = 0
            
            // x-axis
            let xAxis = self.hrHistogram.xAxis
            //  xAxis.axisMinimum = 40
            //  xAxis.axisMaximum = 220
            xAxis.yOffset = 0
            xAxis.labelPosition = .bottom
            xAxis.valueFormatter =  self
            
            self.hrHistogram.legend.enabled = false
            
            self.hrHistogram.notifyDataSetChanged()
        }
    }
}


extension ActivityHRBarChartViewController: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if (Int(value) <= myEfrt.hrHist.count) {
            let potString = myEfrt.hrHist[Int(value-1)].pot
            let substrings = potString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            
            let numbers = substrings.compactMap {
                return Int($0)
            }
            var midval = 0
            if numbers.count > 0 {
                midval = numbers[0]+3 //Width = 5 /2 = 2.5 round to 3
            }
            return "\(midval)"
            //return myEfrt.hrHist[Int(value-1)].pot
        }
        else {
            return ""
        }
    }
}
