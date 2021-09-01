//
//  HomeLast30ViewController.swift
//  eFit
//
//  Created by Paul Williams on 03/11/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import UIKit
import Charts

class HomeLast14ViewController: UIViewController {

    @IBOutlet weak var chart : CombinedChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentChangedNotification(_:)),
            name: DataLoaderNotification.contentUpdated,
            object: nil)
        
        displayChart()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        //displayChart()
        //ToDo : Change this so it updates only if a new data set triggers it
    }
    
    
    
    func displayChart () {
        
        let data = CombinedChartData()
        data.lineData = generateLineData()
        data.barData = generateBarData()
        
        chart.data = data
        
        //Right Axis
        let rightAxis = chart.rightAxis
        rightAxis.enabled = false
        // rightAxis.axisMinimum = 0
        // Settings.setEfrtChartMax(newEfrtChartMax: 50)
        // rightAxis.axisMaximum = Settings.efrtChartMax()
        // rightAxis.labelFont = .systemFont(ofSize: 14)
        // rightAxis.removeAllLimitLines()
        // let llYAxis = ChartLimitLine(limit: 100, label: "100 per day")
        // rightAxis.addLimitLine(llYAxis)
        
        //Left Axis
        let leftAxis = chart.leftAxis
        leftAxis.axisMinimum = 0
        //leftAxis.axisMaximum = Settings.efrtChartMax()
        leftAxis.yOffset = 0
        leftAxis.labelFont = .systemFont(ofSize: 14)
        leftAxis.enabled = false
        
        // x-axis
        let xAxis = chart.xAxis
        xAxis.yOffset = 0
        xAxis.axisMinimum = -0.25
        xAxis.axisMaximum = 13.25
        xAxis.labelPosition = .bottom
        xAxis.granularity = 1
        xAxis.labelFont = .systemFont(ofSize: 14)
        xAxis.enabled = false
        //ToDo : Change this around so that days count backwards
        
        
        //legend
        /*let l = chart.legend
        l.wordWrapEnabled = true
        l.horizontalAlignment = .center
        l.verticalAlignment = .bottom
        l.orientation = .horizontal
        l.drawInside = false
        l.font = .systemFont(ofSize: 16) */
        
        chart.legend.enabled = false
        chart.notifyDataSetChanged()
    } //displayChart
    
    
    func generateLineData() -> LineChartData? {
        let TS = TrainingStress()
        let days = min(14, TS.dayTSS.count)
        let lastDay = TS.fitnessEWMA.count
        if days > 0 {
            
            let entries = (0..<days).map { (i) -> ChartDataEntry in
                return ChartDataEntry (x:Double(i), y: Double(TS.fitnessEWMA[lastDay - days + i]) )
            }
            
            let set = LineChartDataSet(entries: entries, label: "Fitness")
            //set.setColor(CIColor(red: 240/255, green: 238/255, blue: 70/255, alpha: 1))
            set.lineWidth = 3
            set.colors = [Globals.EFRT_GREEN]
            set.drawCirclesEnabled = false
            set.drawFilledEnabled = true
            set.fillColor = Globals.EFRT_GREEN
            //set.circleColors = [Settings.efrtGreen()]
            set.circleRadius = 8
            set.circleHoleRadius = 4
            //set.fillColor = CIColor(red: 240/255, green: 238/255, blue: 70/255, alpha: 1)
            set.mode = .cubicBezier
            set.drawValuesEnabled = true
            set.valueFont = .systemFont(ofSize: 12)
            set.valueTextColor = Globals.EFRT_GREEN
            
            set.axisDependency = .right
            
            return LineChartData(dataSet: set)
        } else {
            return nil
        }
    } //generateLineData
    
    
    func generateBarData() -> BarChartData? {
        let TS = TrainingStress()
        let days = min(14, TS.dayTSS.count)
        let lastDay = TS.dayTSS.count
        if days > 0 {
        
            let entries1 = (0..<days).map { (i) -> BarChartDataEntry in
                return BarChartDataEntry(x: Double(i), y: Double(TS.dayTSS[lastDay - days + i]))
            }
            
            let set1 = BarChartDataSet(entries: entries1, label: "Efrt")
            set1.setColor(Globals.EFRT_BLUE)
            set1.valueTextColor =  Globals.EFRT_BLUE
            set1.valueFont = .systemFont(ofSize: 12)
            set1.axisDependency = .left
            set1.drawValuesEnabled = true
            
            // let groupSpace = 0.06
            // let barSpace = 0.02 // x2 dataset
            let barWidth = 0.55 // x2 dataset
            // (0.45 + 0.02) * 2 + 0.06 = 1.00 -> interval per "group"
            
            let data = BarChartData(dataSets: [set1])
            data.barWidth = barWidth
            
            return data
        } else {
            return nil
        }
    } //generateBarData
    
}

// MARK: - Notification handlers
extension HomeLast14ViewController {
    @objc func contentChangedNotification(_ notification: Notification!) {
        displayChart()
    }
}

