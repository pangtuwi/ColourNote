//
//  ViewController.swift
//  FitForm
//
//  Created by Paul Williams on 06/07/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

// General
// https://www.raywenderlich.com/151741/macos-development-beginners-part-1
// https://www.raywenderlich.com/704-macos-view-controllers-tutorial


// File Access
// https://www.raywenderlich.com/157986/filemanager-class-tutorial-macos-getting-started-file-system

// Charts
// https://github.com/danielgindi/Charts
// example https://medium.com/@OsianSmith/creating-a-line-chart-in-swift-3-and-ios-10-2f647c95392e
// example https://github.com/danielgindi/Charts/blob/master/ChartsDemo-iOS/Swift/Demos

// Table
// https://www.raywenderlich.com/830-macos-nstableview-tutorial

// MAPS
// https://www.raywenderlich.com/548-mapkit-tutorial-getting-started




import Cocoa
import FitDataProtocol
import TrackKit
import Charts
import MapKit
import SwiftyDropbox

class ActivityViewController: NSViewController, NSTableViewDelegate {
    @IBOutlet weak var theFITButton: NSButtonCell!
    @IBOutlet weak var theTCXButton : NSButtonCell!
    @IBOutlet weak var dataTable : NSTableView!
    @IBOutlet weak var hrChart: LineChartView!
    @IBOutlet weak var hrHistogram : BarChartView!
    @IBOutlet weak var mapView: MKMapView!
    
    var myFITData = FITData()
    
    let initialLocation = CLLocation(latitude: 53.1444, longitude: -2.3652)
    let regionRadius: CLLocationDistance = 10000
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataTable.delegate = self
        dataTable.dataSource = self
        
        mapView.delegate = self
        centerMapOnLocation(location: initialLocation)
    
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        if Globals.sharedInstance.LastTCXFileName != "" {
            loadDropboxTCX(TCXFilename: Globals.sharedInstance.LastTCXFileName)
            Globals.sharedInstance.LastTCXFileName = ""
        }
    }
    
    @IBAction func OpenMenuItemSelected(_ sender: Any) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        guard let window = view.window else { return }
        
        let panel = NSOpenPanel()
        panel.directoryURL = home
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["tcx"]
        
        panel.beginSheetModal(for: window) { (result) in
            if result == NSApplication.ModalResponse.OK {
                let fileData = try? Data(contentsOf: panel.urls[0])
                if let fileData = fileData {
                    self.myFITData = FITData(TCXFileData: fileData)
                    self.displayCharts()
                }
                
            }
        }
    }  //OpenMenuItemSelected

    @IBAction func TheFITButtonClicked(_ sender: Any) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        print ("home dir: ", home)
        let fileUrl = home.appendingPathComponent("Garmin")
            .appendingPathComponent("2907712755")
            .appendingPathExtension("fit")
        
        let fileData = try? Data(contentsOf: fileUrl)
        
        // TODO: myFITData to be updated to accept FIT files again as alternative in init
        /*
         if let fileData = fileData {
            myFITData = FITData(fileData: fileData)
            displayCharts()
        }
        */
    } //TheFITButtonClicked
    
    
    func loadDropboxTCX (TCXFilename : String) {
        let client = DropboxClientsManager.authorizedClient
        let DropboxPath = Globals.sharedInstance.DropboxPath + TCXFilename
        // Download to Data
        client?.files.download(path: DropboxPath)
            .response { response, error in
                if let response = response {
                    let responseMetadata = response.0
                    print(responseMetadata)
                    let fileContents = response.1
                    print("File Contents \n", fileContents)
                    self.myFITData = FITData(TCXFileData: fileContents)
                    if self.myFITData.dataOK {
                        self.displayCharts()
                    } else {
                        let alert = NSAlert()
                        alert.messageText = "Could not load TCX File"
                        alert.informativeText = "File has no activities"
                        alert.runModal()
                    }
                } else if let error = error {
                    print(error)
                }
            }
            .progress { progressData in
                print(progressData)
        }
    }
    
    
    @IBAction func TheTCXButtonClicked(_ sender: Any) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        print ("home dir: ", home)
        let fileUrl = home.appendingPathComponent("Garmin")
            .appendingPathComponent("2017-07-30_07-32-55_Sandbach Cycling_Cycling")
            .appendingPathExtension("tcx")
        
        let fileData = try? Data(contentsOf: fileUrl)
        if let fileData = fileData {
            myFITData = FITData(TCXFileData: fileData)
            displayCharts()
        }
    } //TheTCXButtonClicked
    
    
    func displayCharts (){
        //Hr Line Chart - - - - - - - - - - - - - - - - -
        var hrChartEntry = [ChartDataEntry]()
        var altChartEntry = [ChartDataEntry]()
        var powerChartEntry = [ChartDataEntry]()
        var hasFirstCoordinate = false
        var oldCoordinates = initialLocation.coordinate
        var newCoordinates = initialLocation.coordinate
        
        for record in myFITData.records {
            let newPoint = ChartDataEntry (x:(record.timeStamp-myFITData.sessionStartTime)/60, y: record.heartRate)
            hrChartEntry.append(newPoint)
            
            let newAltPoint = ChartDataEntry (x:(record.timeStamp-myFITData.sessionStartTime)/60, y: record.altitude)
            altChartEntry.append(newAltPoint)
            
            let newPwrPoint = ChartDataEntry (x:(record.timeStamp-myFITData.sessionStartTime)/60, y: record.power)
            powerChartEntry.append(newPwrPoint)
            
            // MAP
            if !hasFirstCoordinate {
                oldCoordinates = CLLocationCoordinate2D(latitude: record.latitude, longitude: record.longitude)
                centerMapOn2DLocation(location: oldCoordinates)
                hasFirstCoordinate = true
            } else {
                newCoordinates = CLLocationCoordinate2D(latitude: record.latitude, longitude: record.longitude)
                var area = [oldCoordinates, newCoordinates]
                let polyline = MKPolyline(coordinates: &area, count: area.count)
                mapView.add(polyline)
                //func mapView(MKMapView, didAdd: [MKOverlayRenderer])
                oldCoordinates = newCoordinates
            }
        }
        
        let lineHR = LineChartDataSet(values: hrChartEntry, label: "HeartRate")
        let lineAlt = LineChartDataSet(values: altChartEntry, label: "Altitude")
        let linePower = LineChartDataSet(values: powerChartEntry, label: "Power")
        
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
        
        hrChart.data = data
        hrChart.rightAxis.enabled = true
        hrChart.chartDescription?.text = "Garmin Data"
        hrChart.pinchZoomEnabled = true
        hrChart.dragXEnabled = true  // I think it is true by default anyway?
        hrChart.highlightPerDragEnabled = true
        
        // y-axis 1
        let llYAxis = ChartLimitLine(limit: myFITData.avg_heart_rate(), label: "Average HR")
        llYAxis.lineWidth = 2
        llYAxis.lineDashLengths = [5, 5, 0]
        llYAxis.labelPosition = .rightBottom
        llYAxis.valueFont = .systemFont(ofSize: 10)
        
        let leftAxis = hrChart.leftAxis
        leftAxis.removeAllLimitLines()
        leftAxis.addLimitLine(llYAxis)
        leftAxis.axisMinimum = 0
        leftAxis.axisMaximum = 200
        leftAxis.yOffset = 0
        
        // y-axis 2
        let rightAxis = hrChart.rightAxis
        rightAxis.removeAllLimitLines()
        rightAxis.axisMinimum = 0
        rightAxis.axisMaximum = 800
        rightAxis.yOffset = 0
        
        
        // x-axis
        let xAxis = hrChart.xAxis
        xAxis.axisMinimum = 0
        xAxis.axisMaximum = myFITData.total_timer_time / 60  // Convert to Minutes
        xAxis.yOffset = 0
        xAxis.labelPosition = .bottom
        
        
        //HR Histogram -- - - - - - - - - - - - - - --
        let barDataSet = BarChartDataSet()
        
        //print (myFITData.zones)
        for (index, zone) in myFITData.zones.hrZones.enumerated() {
            let newBar = BarChartDataEntry (x: Double(index), y : zone.timeInZone)
            _ = barDataSet.addEntry(newBar)
        }
        
        let barData = BarChartData(dataSets: [barDataSet])
        hrHistogram.data = barData
        hrHistogram.chartDescription?.text = "Heart Rate Zones"
        hrHistogram.notifyDataSetChanged()
        
        myFITData.rollingMaxAvgPower()
        
        // DataTable - - - - - - - - - - - - -- - - - - - - - - --
        
        dataTable.reloadData()
        
    } //displayCharts

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func centerMapOn2DLocation (location : CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location,
                                                                  regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
  
 
    

} // end of ViewController

extension ActivityViewController: NSTableViewDataSource {
    fileprivate enum CellIdentifiers {
        static let Col1Cell = NSUserInterfaceItemIdentifier("Col1CellID")
        static let Col2Cell = NSUserInterfaceItemIdentifier("Col2CellID")
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 10
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
       // var image: NSImage?
        var cellIdentifier: NSUserInterfaceItemIdentifier
        var image: NSImage?
        var text: String = ""
        
        let hrStats = TrackStats(track: myFITData.hr)
        let powerStats = TrackStats(track: myFITData.power)
        
        if tableColumn == tableView.tableColumns[0] {
           // image = item.icon
            cellIdentifier = CellIdentifiers.Col1Cell
            switch row {
            case 0 :
                text = "\(myFITData.activityType) : \(myFITData.activitySubType)"
            case 1:
                text = "Total Activity Time : \(myFITData.sessionTimeString())"
            case 3:
                text = "HEART RATE"
            case 4 :
                let HRString :String = String(format:"%.0f", myFITData.avg_heart_rate())
                text = "Heartrate Avg : \(HRString) bpm"
            //    cell.imageView?.image = image ?? nil
            case 5 :
                let HRString :String = String(format:"%.0f", myFITData.max_heart_rate)
                text = "Heartrate Max : \(HRString) bpm"
            //    cell.imageView?.image = image ?? nil
            case 6 :
                let HRString :String = String(format:"%.0f", myFITData.zones.hrTSS())
                text = "hrTSS : \(HRString)"
            case 8:
                text = "STATISTICS FUNCTION"
            case 9 :
                let HRString :String = String(format:"%.0f", hrStats.average)
                text = "Heartrate Avg : \(HRString) bpm"
            case  10 :
                let HRString :String = String(format:"%.0f", hrStats.normalised)
                text = "Heartrate Normalised : \(HRString) bpm"
            default:
                text = "-"
            }
        } else if tableColumn == tableView.tableColumns[1] {
            cellIdentifier = CellIdentifiers.Col2Cell
            // image = item.icon
            switch row {
            case 0 :
                text = myFITData.sessionStartDateTimeString()
            case 1 :
                let powerString :String = String(format:"%.0f", myFITData.avg_power())
                text = "Power Avg : \(powerString) W"
            //    cell.imageView?.image = image ?? nil
            case 4:
                text = "STATISTICS POWER"
            case 5 :
                let pwrString :String = String(format:"%.0f", powerStats.average)
                text = "Power Avg : \(pwrString) Watts"
            case  6 :
                let pwrString :String = String(format:"%.0f", powerStats.normalised)
                text = "NP : \(pwrString) Watts"
                
                
            case 9 :
                text = "FTP Setting : \(Globals.sharedInstance.FTP) W"
            case 10 :
                let swimTSSString :String = String(format:"%.0f", myFITData.zones.swimTSS())
                text = "Swim TSS : \(swimTSSString)"
            default:
                text = "-"
            }
        } else {
            text = "-"
            cellIdentifier = CellIdentifiers.Col1Cell
        }
        
        
        if let cell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.imageView?.image = image ?? nil
            return cell
        }
        return nil
    }
} //extension ViewController: NSTableViewDataSource

extension ActivityViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let temp = MKOverlayRenderer()
        if (overlay is MKPolyline) {
            let pr = MKPolylineRenderer(overlay: overlay)
            pr.strokeColor = NSUIColor.blue //UIColor.redColor()
            pr.lineWidth = 5
            return pr
        }
        return temp
    }  // renderer for Overlay of MKPolyLine
 
}

