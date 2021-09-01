//
//  WeeksViewController.swift
//  eFrt
//
//  Created by Paul Williams on 01/01/2019.
//  Copyright © 2019 Paul Williams. All rights reserved.
//

import UIKit
import Charts

class HomeWeeksViewController: UIViewController {
    
    @IBOutlet weak var chart : CombinedChartView!
    var TS = TrainingStress()
    var weeks : Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentChangedNotification(_:)),
            name: DataLoaderNotification.contentUpdated,
            object: nil)
        
        displayChart()

    }
    
    func displayChart () {
        TS = TrainingStress()
        weeks = TS.weekTSS.count
        
        let data = CombinedChartData()
        data.lineData = generateLineData()
        data.barData = generateBarData()
        chart.data = data
        
        //Right Axis
        let rightAxis = chart.rightAxis
        rightAxis.enabled = false
        
        //Left Axis
        let leftAxis = chart.leftAxis
        leftAxis.axisMinimum = 0
        //leftAxis.axisMaximum = Settings.efrtChartMax()
        leftAxis.yOffset = 0
        leftAxis.labelFont = .systemFont(ofSize: 14)
        leftAxis.enabled = false
        
        // x-axis
        let xAxis = chart.xAxis
        xAxis.axisMinimum = -0.5
        xAxis.axisMaximum = Double(weeks) - 0.5
        xAxis.yOffset = 0
        xAxis.labelPosition = .bottom
        xAxis.granularity = 1
        xAxis.labelFont = .systemFont(ofSize: 14)
        xAxis.enabled = false
        //ToDo : Change this around so that days count backwards
        
        chart.legend.enabled = false
        chart.notifyDataSetChanged()
    } //displayChart

    func generateLineData() -> LineChartData? {
        return nil
    } //generateLineData
    
    
    func generateBarData() -> BarChartData? {
        if self.weeks > 0 {
            let entries1 = (0..<weeks).map { (i) -> BarChartDataEntry in
                return BarChartDataEntry(x: Double(i), y: Double(TS.weekTSS[i]))
            }
            
            let set1 = BarChartDataSet(entries: entries1, label: "Weekly Efrt")
            set1.setColor(Globals.EFRT_ORANGE)
            set1.valueTextColor =  Globals.EFRT_ORANGE
            set1.valueFont = .systemFont(ofSize: 12)
            set1.axisDependency = .left
            set1.drawValuesEnabled = true
            
            let data = BarChartData(dataSets: [set1])
            data.barWidth = 0.75
            return data
        } else {
            return nil
        }
    } //generateBarData
 

}

// MARK: - Notification handlers
extension HomeWeeksViewController {
    @objc func contentChangedNotification(_ notification: Notification!) {
        displayChart()
    }
}
