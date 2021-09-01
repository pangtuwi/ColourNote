//
//  WindowController.swift
//  FitForm
//
//  Created by Paul Williams on 25/08/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Cocoa

class WindowController: NSTabViewController {
    
 //   @IBOutlet weak var window : NSWindow!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.toggleFullScreen(self)
    }
    
}
