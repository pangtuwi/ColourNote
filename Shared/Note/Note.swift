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
    var colorIndex : Int
    var categoryId : Int
    var isDeleted : Bool
    var deletedDate : Int?


    init() {
        noteId = 0
        noteName = ""
        editedTime = 0
        noteText = ""
        colorIndex = 0
        categoryId = 0
        isDeleted = false
        deletedDate = nil

    }

    init(noteId : Int, noteName : String, editedTime : Int, noteText : String, colorIndex : Int, categoryId: Int = 0, isDeleted: Bool = false, deletedDate: Int? = nil) {
        self.noteId = noteId
        self.noteName = noteName
        self.editedTime = editedTime
        self.noteText = noteText
        self.colorIndex = colorIndex
        self.categoryId = categoryId
        self.isDeleted = isDeleted
        self.deletedDate = deletedDate
    }

}

