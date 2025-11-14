//
//  FirstViewController.swift
//  eFit
//
//  Created by Paul Williams on 27/09/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import UIKit
//

class NoteViewController: UIViewController {


    @IBOutlet weak var titleLabel : UILabel!    

    override func viewDidLoad() {
        super.viewDidLoad()
    } //viewDidLoad

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)


        if NoteRecords.instance.getNote(searchNoteId:  Globals.sharedInstance.noteIDToDisplay) ?? NoteRecords.instance.getLatestNote() != nil {
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Changed Tab View - clear activityIDToDisplay
        Globals.sharedInstance.noteIDToDisplay = 0
    }
}

