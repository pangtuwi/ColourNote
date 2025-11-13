//
//  NoteViewController.swift
//  ColourNote
//
//  Created by Paul Williams on 30/12/2021.
//  Copyright © 2021 Paul Williams. All rights reserved.
//

import UIKit

class Note2ViewController: UIViewController {
    
    @objc func addTapped(_ sender: UIBarButtonItem) {
         print("Test Right button", self.navigationItem.title)
     }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addTapped))
    }
}
