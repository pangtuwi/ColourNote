//
//  Note.swift
//  ColourNoteProj
//
//  Created by Paul Williams on 03/10/2021.
//  Copyright © 2021 Paul Williams. All rights reserved.
//

import Foundation

class Note {
    
    
    var noteId : Int
    var noteName : String
    let editedTime : Int
    var noteText : String

    
    init() {
        noteId = 0
        noteName = ""
        editedTime = 0
        noteText = ""
        
    }
    
    init(noteId : Int, noteName : String, editedTime : Int, noteText : String) {
        self.noteId = noteId
        self.noteName = noteName
        self.editedTime = editedTime
        self.noteText = noteText
    }
    
}

