//
//  TrainingViewController.swift
//  FitForm
//
//  Created by Paul Williams on 19/08/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

// Dropbox
// https://github.com/dropbox/SwiftyDropbox
// https://github.com/dropbox/SwiftyDropbox#register-your-application
// Dropbox App access created  https://www.dropbox.com/developers/apps/info/t3rygg2sue2w8yj
// App key  t3rygg2sue2w8yj
// App secret ejsn30moslmymma

//  Example From https://github.com/dropbox/PhotoWatch/blob/master/PhotoWatch/ViewController.swift

import Cocoa
import SwiftyDropbox

class TrainingViewController: NSViewController, NSTableViewDelegate {

    @IBOutlet weak var dataTable : NSTableView!
    var myFITData = FITData()
    var activities : [Activity] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataTable.delegate = self
        dataTable.dataSource = self
        dataTable.target = self
        dataTable.doubleAction = #selector(tableViewDoubleClick(_:))
        
        activities = ActivityRecords.instance.getActivities()
        activities.sort { $0.starttime > $1.starttime }
        dataTable.reloadData()
        
    }
    
    
    override func viewDidAppear() {
        super.viewDidAppear()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // wait 2 seconds (arbritrary) for dropbox to be ready
            self.dropboxLoadFileList()

            //ToDo: Figure out how to do this without the delay
        }
    } //viewDidAppear
   

    
    @IBAction func dropboxFileList(_ sender: Any) {
        dropboxLoadFileList()
    } //dropboxFileList
    
    @IBAction func OpenDB (_ sender: Any) {
        activities = ActivityRecords.instance.getActivities()
        activities.sort { $0.starttime > $1.starttime }
    }
    
    
    @IBAction func InsertDB (_ sender : Any) {
        if let id = ActivityRecords.instance.addActivity(cfilename: "anotherfilename", csport: 2, cduration: 123445) {
            print("Added \(id)")
        }
        
    }
    
   /* @IBAction func OpenDropboxMenuItemSelected(_ sender: Any) {
        myButtonInControllerPressed()
  
    } */
    
    @IBAction func dropboxAuthenticate (_ sender: Any) {
        DropboxClientsManager.authorizeFromController(sharedWorkspace: NSWorkspace.shared,
                                                      controller: self,
                                                      openURL: { (url: URL) -> Void in
                                                        NSWorkspace.shared.open(url)
        })
    }
    
    @objc func tableViewDoubleClick(_ sender:AnyObject) {
        let selectedItem = activities[dataTable.selectedRow]
        Globals.sharedInstance.LastTCXFileName = selectedItem.filename
        let tabBarController: NSTabViewController = (self.parent as? NSTabViewController)!
        tabBarController.selectedTabViewItemIndex = 0
    }
    
    
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
                    let newFITData = FITData(TCXFileData: fileContents)
                    if newFITData.dataOK {
                        let id = ActivityRecords.instance.addActivityFromFITData(cfilename: TCXFilename, cFITData : newFITData)
                        self.dataTable.reloadData() 
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
    
    
    // TODO: rewrite this to use the new Dropbox class
    
    func dropboxLoadFileList() {
        let client = DropboxClientsManager.authorizedClient
        _ = client?.files.listFolder(path: "/Apps/tapiriik").response { response, error in
            if let result = response {
                //self.filenames = []
                for entry in result.entries {
                    if entry.name.hasSuffix(".tcx") || entry.name.hasSuffix(".fit") {
                        if !ActivityRecords.instance.activityExists(cfilename: entry.name) {
                            self.loadDropboxTCX(TCXFilename: entry.name)
                        }
                     
                        self.activities = ActivityRecords.instance.getActivities()
                        self.activities.sort { $0.starttime > $1.starttime }
                        self.dataTable.reloadData()
                    }
                }
            } else {
                print("DROPBOX Error: \(error!) \n")
            }
        }
    } //dropboxLoadFileList
    
}

extension TrainingViewController: NSTableViewDataSource {
    fileprivate enum CellIdentifiers {
        static let Col1Cell = NSUserInterfaceItemIdentifier("TRCol1CellID")
        static let Col2Cell = NSUserInterfaceItemIdentifier("TRCol2CellID")
        static let Col3Cell = NSUserInterfaceItemIdentifier("TRCol3CellID")
        static let Col4Cell = NSUserInterfaceItemIdentifier("TRCol4CellID")
        static let Col5Cell = NSUserInterfaceItemIdentifier("TRCol5CellID")
        
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return activities.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var cellIdentifier: NSUserInterfaceItemIdentifier
        var text: String = ""
        
        if tableColumn == tableView.tableColumns[0] {
            cellIdentifier = CellIdentifiers.Col1Cell
            text = "\(timeDateString(unixTime: activities[row].starttime))"
        } else if tableColumn == tableView.tableColumns[1] {
            text = activities[row].filename
            cellIdentifier = CellIdentifiers.Col2Cell
        } else if tableColumn == tableView.tableColumns[2] {
            text = "\(activities[row].sport)"
            cellIdentifier = CellIdentifiers.Col3Cell
        } else if tableColumn == tableView.tableColumns[3] {
            text = "\(timeString(unixTime: activities[row].duration))"
            cellIdentifier = CellIdentifiers.Col4Cell
        } else {
            text = "\(activities[row].tss)"
            cellIdentifier = CellIdentifiers.Col5Cell
        }
        
        
        if let cell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
} //extension ViewController: NSTableViewDataSource
