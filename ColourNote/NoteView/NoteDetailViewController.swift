//
//  NoteViewController.swift
//  ColourNoteProj
//
//  Created by Paul Williams on 10/10/2021.
//  Copyright © 2021 Paul Williams. All rights reserved.
//


import UIKit

class NoteDetailViewController: UIViewController, UITextViewDelegate {

   // @IBOutlet weak var textView : UITextView!
   // @IBOutlet weak var tableView2 : UITableView!
    @IBOutlet weak var textView: LinedTextView!
       
    
    
   /* struct ActivityDetail : Codable {
        let description : String
        let value : String
        init(descr : String, val : String){
            description = descr
            value = val
        }
    } */
    
    private var displayedNoteID : Int = 0
    private var textHasChanged : Bool = false
  //  private var tableData : [ActivityDetail] = []
   // private var tableEfrtData : [ActivityDetail] = []
    
    var lastNoteID = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        
    /*    NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentChangedNotification(_:)),
            name: DataLoaderNotification.contentUpdated,
            object: nil)
 */
        
   //     tableView1.dataSource = self
    //    tableView2.dataSource = self
        
    } //viewDidLoad
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if let note = NoteRecords.instance.getNote(searchNoteId:
            Globals.sharedInstance.noteIDToDisplay) ?? NoteRecords.instance.getLatestNote() {
            displayData(note: note)
        }
        textHasChanged = false
    }//viewDidAppear
        
    override func viewWillDisappear(_ animated: Bool) {
        //let userDefault = UserDefaults.standard
        //userDefault.set("value", forKey: "homeTeamName")
        if textHasChanged {
            NoteRecords.instance.updateNoteText(changedNoteId: Globals.sharedInstance.noteIDToDisplay, newText: textView.text)
        }
    }
    
    func displayData (note : Note) {
        textView.text = note.noteText
        textView.backgroundColor = Globals.CN_LIGHT_COLORS[note.colorIndex]
    }//displayData
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        textView.setNeedsDisplay()
        print("scrolling")
    }
    
    func textViewDidChange(_ textView: UITextView) {
        textHasChanged = true
    }

// MARK: - Notification handlers
/*extension AnalysisDetailViewController {
    @objc func contentChangedNotification(_ notification: Notification!) {
       // displayData()
    }
} */

}
