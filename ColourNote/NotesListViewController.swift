//
//  SecondViewController.swift
//  eFit
//
//  Created by Paul Williams on 27/09/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//
// https://www.raywenderlich.com/464-storyboards-tutorial-for-ios-part-1
// https://stackoverflow.com/questions/24475792/how-to-use-pull-to-refresh-in-swift
// https://developer.apple.com/library/archive/documentation/ToolsLanguages/Conceptual/Xcode_Overview/ConnectingObjectstoCode.html
// https://stackoverflow.com/questions/56662886/how-to-filter-array-model-data-based-on-user-input-in-text-field


import UIKit
//import SwiftyDropbox

class NotesListViewController: UITableViewController, UITextFieldDelegate {
    
    var notes : [Note] = []
   // let array : Array<String> = ["1", "2", "3"];
    var filteredNotes = [Note]() {
        didSet{
            self.tableView.reloadData()
        }
    }
    
    @IBOutlet weak var StatusLabel : UILabel!
    @IBOutlet weak var SearchTextEditor: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SearchTextEditor.delegate = self
       // filteredNotes = notes
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentChangedNotification(_:)),
            name: DataLoaderNotification.contentUpdated,
            object: nil)
        
       // _ = ActivityRecords.instance.deleteActivity(cActivityId : 3923275188)
       //    DataLoader.sharedInstance.deleteFromCache(ActivityId: 3923275188)
        
        refreshControl = UIRefreshControl()
        refreshControl!.attributedTitle = NSAttributedString(string: "Pulll to refresh")
        refreshControl!.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        
        //updateTrainingList()
        updateNotesList()
    } //viewDidLoad
    
    
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(true)
    } //viewDidAppear
    
    func updateNotesList() -> Void {
        notes = NoteRecords.instance.getNotes()
        notes.sort { $0.editedTime > $1.editedTime }
        filteredNotes = notes
        
        tableView.reloadData()
       // StatusLabel.text = "\(notes.count) Notes"
        StatusLabel.text = "\(filteredNotes.count) Notes"
    }
    
    
    @objc func handleRefresh(refreshControl: UIRefreshControl) {
        DispatchQueue.main.async {
            self.StatusLabel.text = "Checking Server for new files..."
        }
        
        DispatchQueue.global(qos: .utility).async {
            DataLoader.sharedInstance.requestSync()
        }
        
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else {
                return
            }
            DataLoader.sharedInstance.loadNewActivityList(whenDone: self.gotList)
            // 2
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {  [weak self] in
                self!.refreshControl!.endRefreshing()
                self!.StatusLabel.text = "\(self!.notes.count) Notes"
            }
        }
    } //handleRefresh
        

    
   // func gotList (hasNewFiles : Bool) -> Void {
    func gotList (newActivityList : [Int]) -> Void {
        //ToDo: Add message for when Server not available
        if newActivityList.count > 0 {
            DispatchQueue.main.async {
                self.StatusLabel.text = "Found \(newActivityList.count) new activities on Server.  Updating..."
            }
            if newActivityList.count <= 10 {
                DataLoader.sharedInstance.downloadEFRTFromList(list: newActivityList)
            } else {
                DataLoader.sharedInstance.downloadMissingEFRT()
            }
         /*   var delaycounter = 0
            var newActivityList2 = newActivityList
            newActivityList2.reverse()
            for newActivityId in newActivityList2 {
                //ToDo : Change this to work off a scheduler with stack?
                //https://gist.github.com/Thomvis/b378f926b6e1a48973f694419ed73aca
                delaycounter += 1
                let newDespatchTime =  DispatchTime.now() + DispatchTimeInterval.seconds(delaycounter/4)
                DispatchQueue.main.asyncAfter(deadline: newDespatchTime) {  [weak self] in
                    DataLoader.sharedInstance.getEfrt(whenDone: self!.gotNewActivity, ActivityId: newActivityId)
                }
 
            } */
        } else {
            DispatchQueue.main.async {
                self.StatusLabel.text = "No new activities on EFRT server"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.StatusLabel.text = "Checking on connect.garmin.com"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.StatusLabel.text = "\(self.notes.count) notes"
            }
        }
    } //gotList
    
    
    func gotNewActivity (efrt : Efrt) -> Void {
        DispatchQueue.main.async {
            self.StatusLabel.text =  "Activity downloaded"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.updateNotesList()
        }
    } //gotNewActivity
    

}  //TrainingViewController


extension NotesListViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      //  return notes.count
        return filteredNotes.count
    }
    
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityCell", for: indexPath)
        // ToDo : Fix occasional Fatal error : Index out of range
        //print ("Training View Table View loading \(indexPath.row) of \(filteredNotes.count)")
        if (indexPath.row <= notes.count) {
           // let activity = activities[indexPath.row]
            let note = filteredNotes[indexPath.row]
           /* if (activity.tss == -1) {
                cell.textLabel?.text = "...pending download"
            } else { */
            cell.textLabel?.text = "\(note.noteName)"
           // }
            cell.detailTextLabel?.text = "\(note.noteId) - \(note.editedTime)"

                cell.backgroundColor = Globals.CN_LIGHT_COLORS[note.colorIndex]
 
         /*   if activity.ignore {
                cell.textLabel?.textColor = Globals.EFRT_LTGREY
            } else {
                cell.textLabel?.textColor = Globals.EFRT_DKGREY
            } */
        } else {
            cell.textLabel?.text = "Loading..."
            cell.detailTextLabel?.text = ""
        }
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        Globals.sharedInstance.activityIDToDisplay = activities[indexPath.row].activityId
        Globals.sharedInstance.noteIDToDisplay = filteredNotes[indexPath.row].noteId
        //tabBarController!.selectedIndex = 2
        let NoteViewController = storyboard?.instantiateViewController(withIdentifier: "NoteViewController")
        NoteViewController!.modalPresentationStyle = .fullScreen
        NoteViewController?.modalTransitionStyle = .crossDissolve
              
        present(NoteViewController!, animated: true, completion: nil)
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        //ACTION to IGNORE an Activity
    /*    let ignoreAction = UIContextualAction(style: .normal, title: "ignore",
                                              handler: { (action, view, completionHandler) in
            if (self.activities[indexPath.row].ignore == false) {
                _ = ActivityRecords.instance.setActivityIgnore(changedActivityId: self.activities[indexPath.row].activityId, ignore: true)
                self.activities[indexPath.row].ignore = true
            } else {
                _ = ActivityRecords.instance.setActivityIgnore(changedActivityId: self.activities[indexPath.row].activityId, ignore: false)
                self.activities[indexPath.row].ignore = false
            }
            NotificationCenter.default.post(name: DataLoaderNotification.contentUpdated, object: nil)
            self.tableView.reloadData()
            completionHandler(true)
                        
        })
        ignoreAction.image = UIImage(named: "medal")
        ignoreAction.backgroundColor = Globals.EFRT_ORANGE */
        
        //Action to re-DOWNLOAD an Activity
        let downloadAction = UIContextualAction(style: .normal, title: "download",
                                              handler: { (action, view, completionHandler) in
            DataLoader.sharedInstance.deleteFromCache(ActivityId: self.notes[indexPath.row].noteId )
            DataLoader.sharedInstance.getEfrt(whenDone: self.gotNewActivity, ActivityId: self.notes[indexPath.row].noteId )
            NotificationCenter.default.post(name: DataLoaderNotification.contentUpdated, object: nil)
            self.tableView.reloadData()
            completionHandler(true)
        })
        downloadAction.image = UIImage(named: "download")
        downloadAction.backgroundColor = Globals.EFRT_BLUE
        
        //let configuration = UISwipeActionsConfiguration(actions: [ignoreAction, downloadAction])
        let configuration = UISwipeActionsConfiguration(actions: [downloadAction])
        return configuration
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        //print("input text is : \(string)")
        //print (" text Field is now : \(textField.text)")
        let searchText = textField.text!
        
        filteredNotes = notes.filter( { $0.noteName.range(of: searchText, options: .caseInsensitive) != nil})
        tableView.reloadData()
        return true
    }
    
}

// MARK: - Notification handlers
extension NotesListViewController {
    @objc func contentChangedNotification(_ notification: Notification!) {
        updateNotesList()
        let app = UIApplication.shared
        app.applicationIconBadgeNumber = 0
       // print ("Content Change notification recieved in TrainingViewController")
    }
}



