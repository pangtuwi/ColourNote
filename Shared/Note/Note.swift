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
    var uuid : String
    var noteName : String
    let editedTime : Int
    var noteText : String
    var categoryId : Int
    var isDeleted : Bool
    var deletedDate : Int?
    var contentFormat : String


    init() {
        noteId = 0
        uuid = UUID().uuidString
        noteName = ""
        editedTime = 0
        noteText = ""
        categoryId = 0
        isDeleted = false
        deletedDate = nil
        contentFormat = "markdown"

    }

    init(noteId : Int, uuid: String? = nil, noteName : String, editedTime : Int, noteText : String, categoryId: Int = 0, isDeleted: Bool = false, deletedDate: Int? = nil, contentFormat: String = "markdown") {
        self.noteId = noteId
        self.uuid = uuid ?? UUID().uuidString
        self.noteName = noteName
        self.editedTime = editedTime
        self.noteText = noteText
        self.categoryId = categoryId
        self.isDeleted = isDeleted
        self.deletedDate = deletedDate
        self.contentFormat = contentFormat
    }

}

