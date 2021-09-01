//
//  FFFController.swift
//  FitForm
//
//  Created by Paul Williams on 23/09/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//
// Combined Chart
// https://github.com/danielgindi/Charts/blob/master/ChartsDemo-iOS/Swift/Demos/CombinedChartViewController.swift


import Cocoa
import Charts

class FFFController: NSViewController {

    @IBOutlet weak var chart : CombinedChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayChart()
    }
    
    func displayChart () {

        let data = CombinedChartData()
        data.lineData = generateLineData()
        data.barData = generateBarData()
        
        chart.data = data
        
        //Right Axis
        let rightAxis = chart.rightAxis
        rightAxis.axisMinimum = 0
        rightAxis.axisMaximum = 200
        rightAxis.labelFont = .systemFont(ofSize: 14)
        rightAxis.removeAllLimitLines()
        let llYAxis = ChartLimitLine(limit: 100, label: "100 per day")
        rightAxis.addLimitLine(llYAxis)
        
        //Left Axis
        let leftAxis = chart.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.axisMaximum = 200
        leftAxis.yOffset = 0
        leftAxis.labelFont = .systemFont(ofSize: 14)
        
        // x-axis
        let xAxis = chart.xAxis
        xAxis.yOffset = 0
        xAxis.labelPosition = .bottom
        xAxis.granularity = 10
        xAxis.labelFont = .systemFont(ofSize: 14)
        
        //legend
        let l = chart.legend
        l.wordWrapEnabled = true
        l.horizontalAlignment = .center
        l.verticalAlignment = .bottom
        l.orientation = .horizontal
        l.drawInside = false
        l.font = .systemFont(ofSize: 16)
        
        chart.notifyDataSetChanged()
    } //displayChart
    
    func generateLineData() -> LineChartData {
        let TS = TrainingStress()
        let days = TS.dayTSS.count
        
        let entries = (0..<days).map { (i) -> ChartDataEntry in
            return ChartDataEntry (x:Double(i), y: Double(TS.fitnessEWMA[i]) )
        }

        let set = LineChartDataSet(values: entries, label: "Fitness Tracker")
        //set.setColor(CIColor(red: 240/255, green: 238/255, blue: 70/255, alpha: 1))
        set.lineWidth = 2.5
        //set.setCircleColor(UIColor(red: 240/255, green: 238/255, blue: 70/255, alpha: 1))
        set.circleRadius = 5
        set.circleHoleRadius = 2.5
        //set.fillColor = CIColor(red: 240/255, green: 238/255, blue: 70/255, alpha: 1)
        set.mode = .cubicBezier
        set.drawValuesEnabled = true
        set.valueFont = .systemFont(ofSize: 16)
        //set.valueTextColor = CIColor(red: 240/255, green: 238/255, blue: 70/255, alpha: 1)
        
        set.axisDependency = .right
        
        return LineChartData(dataSet: set)
    } //generateLineData
    
    
    func generateBarData() -> BarChartData {
        let TS = TrainingStress()
        let days = TS.dayTSS.count
        
        let entries1 = (0..<days).map { (i) -> BarChartDataEntry in
            return BarChartDataEntry(x: Double(i), y: Double(TS.dayTSS[i]))
        }
        
        let set1 = BarChartDataSet(values: entries1, label: "Daily Effort")
        set1.setColor(NSColor(red: 60/255, green: 220/255, blue: 78/255, alpha: 1))
      //  set1.valueTextColor = UIColor(red: 60/255, green: 220/255, blue: 78/255, alpha: 1)
        set1.valueFont = .systemFont(ofSize: 10)
        set1.axisDependency = .left
        
        let groupSpace = 0.06
        let barSpace = 0.02 // x2 dataset
        let barWidth = 0.45 // x2 dataset
        // (0.45 + 0.02) * 2 + 0.06 = 1.00 -> interval per "group"
        
        let data = BarChartData(dataSets: [set1])
        data.barWidth = barWidth
        
        return data
    } //generateBarData
    
}
