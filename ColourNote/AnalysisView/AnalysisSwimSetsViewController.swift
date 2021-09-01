//
//  AnalysisSwimSetsViewController.swift
//  eFrt
//
//  Created by Paul Williams on 26/01/2019.
//  Copyright © 2019 Paul Williams. All rights reserved.
//

import UIKit
import Charts

class AnalysisSwimSetsViewController: UIViewController {

    var myActivity = Activity()
    var myEfrt = Efrt()
    
    @IBOutlet weak var chart : BarChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Globals.EFRT_BKGREY
    } //viewDidLoad
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if let myActivity = ActivityRecords.instance.getActivity(searchActivityId:  Globals.sharedInstance.activityIDToDisplay) ?? ActivityRecords.instance.getLatestActivity() {
            DataLoader.sharedInstance.getEfrt(whenDone: displayBarChart, ActivityId : myActivity.activityId)
        }
    } //viewDidAppear
    
    
    func displayBarChart (efrt : Efrt) -> Void {
        DispatchQueue.main.async {
           /* let barDataSet = BarChartDataSet()
            
            self.myEfrt = efrt
            
            var i  = 0
            for bt in efrt.bestTimes {
                i = i + 1
                let newBar = BarChartDataEntry (x: Double(i), y : Double(bt.minTime100))
                _ = barDataSet.addEntry(newBar)
            }
            
            barDataSet.setColor(Globals.EFRT_ORANGE)
            barDataSet.drawValuesEnabled = false
            //barDataSet.setColor(0x0F90CB)
            
            
            let barData = BarChartData(dataSets: [barDataSet])
            // barData.barWidth = 10
            
            self.chart.data = barData
            //hrHistogram.chartDescription?.text = "Heart Rate Distribution"
            self.chart.rightAxis.enabled = false
            self.chart.pinchZoomEnabled = false
            self.chart.dragXEnabled = false
            self.chart.drawBarShadowEnabled = false
            //hrHistogram.drawValueAboveBarEnabled = false
            //hrChart.highlightPerDragEnabled = true
            
            let leftAxis = self.chart.leftAxis
            // leftAxis.axisMinimum = 0
            // leftAxis.axisMaximum = 240
            leftAxis.axisMinimum = 0
            leftAxis.yOffset = 0
            
            // x-axis
            let xAxis = self.chart.xAxis
            xAxis.axisMinimum = 0.5 //Double(i) - 0.5
            xAxis.axisMaximum = Double(i) + 0.5
            //xAxis.setLabelCount(i, force: true)
            xAxis.granularity = 1
            //xAxis.yOffset = 0
            xAxis.labelPosition = .bottom
            xAxis.valueFormatter =  self
            
            self.chart.legend.enabled = false
            
            self.chart.notifyDataSetChanged() */
        }
    }
}

extension AnalysisSwimSetsViewController: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if ((Int(value) <= myEfrt.bestTimes.count) && (value >= 1)) {
            return "\(myEfrt.bestTimes[Int(value-1)].d)m"}
        else {
            return ""
        }
    }
}
