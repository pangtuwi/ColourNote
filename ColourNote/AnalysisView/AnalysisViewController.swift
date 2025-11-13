//
//  AnalysisViewController.swift
//  eFrt
//
//  Created by Paul Williams on 18/01/2019.
//  Copyright © 2019 Paul Williams. All rights reserved.
//
// https://robkerr.com/configuring-a-uiscrollview-in-a-storyboard-with-no-code/
// Instructions copied at bottom

import UIKit

class AnalysisViewController: UIViewController {
    
    @IBOutlet weak var dateLabel : UILabel!
    @IBOutlet weak var sportLabel : UILabel!
    @IBOutlet weak var TSSLabel : UILabel!
    
    @IBOutlet weak var headerContainer : UIView!
    @IBOutlet weak var container1 : UIView!
    @IBOutlet weak var container2 : UIView!
    @IBOutlet weak var container3 : UIView!
    @IBOutlet weak var container4 : UIView!
    @IBOutlet weak var container5 : UIView!
    
    //var blocks = [UIViewController]()

    @objc func addTapped(_ sender: UIBarButtonItem) {
         print("Test Right button", self.navigationItem.title)
     }
   
     var addButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addTapped))
        
        self.view.backgroundColor = Globals.EFRT_BKGREY
            //Settings.efrtBkGrey()
        headerContainer.backgroundColor = Globals.EFRT_BKGREY
        container1.backgroundColor = Globals.EFRT_BKGREY
  //      container2.backgroundColor = Globals.EFRT_BKGREY
   //     container3.backgroundColor = Globals.EFRT_BKGREY
   //     container4.backgroundColor = Globals.EFRT_BKGREY
   //     container5.backgroundColor = Globals.EFRT_BKGREY
        
   /*     let block1: UIViewController! = storyboard?.instantiateViewController(withIdentifier: "AnalysisHRChart")
        block1.view.backgroundColor = Globals.EFRT_BKGREY
        block1.view.frame = self.container1.bounds 
        self.container1.addSubview(block1.view)
        self.addChild(block1)
        block1.didMove(toParent: self)
 */
   /*
        let block2: UIViewController! = storyboard?.instantiateViewController(withIdentifier: "ActivityMap")
        block2.view.frame = self.container2.bounds
        self.container2.addSubview(block2.view)
        self.addChild(block2)
        block2.didMove(toParent: self)
        
 */
        let block1: UIViewController! = storyboard?.instantiateViewController(withIdentifier: "NoteDetail")
        block1.view.frame = self.container1.bounds
        self.container1.addSubview(block1.view)
        self.addChild(block1)
        block1.didMove(toParent: self)
     /*
        let block4: UIViewController! = storyboard?.instantiateViewController(withIdentifier: "ActivityLineChart")
        block4.view.frame = self.container4.bounds
        self.container4.addSubview(block4.view)
        self.addChild(block4)
        block4.didMove(toParent: self)
        
        let block5: UIViewController! = storyboard?.instantiateViewController(withIdentifier: "ActivitySwimSets")
        block5.view.frame = self.container5.bounds
        self.container5.addSubview(block5.view)
        self.addChild(block5)
        block5.didMove(toParent: self)
 */

    } //viewDidLoad
    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        // var activity : Activity

    /*    if let activity = ActivityRecords.instance.getActivity(searchActivityId:
            Globals.sharedInstance.activityIDToDisplay) ?? ActivityRecords.instance.getLatestActivity() {
            
            //Set Labels
            dateLabel.text = "\(activity.activityName)"
            sportLabel.text = "\(activity.sportString())  |  \(sessionTimeString(timer_time: activity.duration))  |  \(activity.agoString())"
            TSSLabel.text = "\(activity.tss) TSS"
 
 */
            
            if let note = NoteRecords.instance.getNote(searchNoteId:
                Globals.sharedInstance.noteIDToDisplay) ?? NoteRecords.instance.getLatestNote() {
                
                //Set Labels
                dateLabel.text = "\(note.noteName)"
                sportLabel.text = "\(note.noteId)"
               // TSSLabel.text = "\(note.editedTime) EditTime"
                TSSLabel.text = "\(dateString(unixTime: note.editedTime))"
                //print (dateString(note.editedTime))
            
            //Hide Unnecessary Blocks
     /*       if activity.shouldDrawMap() {
                self.container2.isHidden = false
            } else {
                self.container2.isHidden = true
            }
            
            if activity.hasHeartRate(){
                self.container1.isHidden = false
                self.container4.isHidden = false
            } else {
                self.container1.isHidden = true
                self.container4.isHidden = true
            }
            
            if activity.isSwim(){
                self.container5.isHidden = false
            } else {
                self.container5.isHidden = true
            }
 */
        }
    } //viewDidAppear
    
    override func viewWillDisappear(_ animated: Bool) {
        // Changed Tab View - clear activityIDToDisplay
        Globals.sharedInstance.activityIDToDisplay = 0
    } //viewWillDissapear

}

/* Create a new Single View App
 In the default Main.Storyboard, select the View Controller Scene, then select the Size Inspector, then change the View Controller Scene’s Simulated size to Freeform, and the Height property to 1500
 
 Create seven views, one over the other, assigning the following colors of the rainbow: #9400D3, #4B0082, #0000FF, #00FF00, #FFFF00, #FF7F00, #FF0000
 
 Add a height constraint to each view, fixing each to 200 points
 
 Highlight all seven views in the Document Outline, and select from the Xcode menu: Editor / Embed In / Stack View.
 
 Highlight he new UIStackView in the Document Outline, and in the Attributes Inspector, set the following properties on the UIStackView:
     a. Axis = Vertical
     b. Distribution = Equal Spacing
     c. Spacing = 10
 
 Highlight the new UIStackView in the Document Outline, and select from the Xcode menu: Editor / Embed In / Scroll View
 
 Highlight the new Scroll View in the Document Outline, and create constraints 1–4 from the above Scroll View Constraints section list.
     [Scroll View].[Trailing Space] = [Safe Area]
     [Scroll View].[Leading Space] = [Safe Area]
     [Scroll View].[Bottom Space] = [Safe Area]
     [Scroll View].[Top Space] = [Safe Area]
 
 Now in the Document Outline, click on the UIStackView. Now hold down the ⌘ key and click on the Top Level View. With both these views highlighted, click on the Add New Constraints button, select the Equal Widths checkbox, and press the Add Constraints button to save this constraint.
 
 You don’t need constraint #6 because the Content View in this layout is a UIStackView that has an intrinsic height, since we fixed the height of all the rainbow UIView controls and set a spacing of 10 points. This gives the UIStackView a fixed height of (7 * 200) + (6 * 10) = 1460, which the UIScrollView will read at runtime to use to position and scroll the view.
 
 Note PW
 - in addition I had to constrain the Stack View to its superView - all 4 directions = 0
 */

