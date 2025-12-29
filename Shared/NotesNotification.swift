//
//  NotesNotification.swift
//  ColourNote
//
//  Created by Paul Williams on 03/11/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let notesContentUpdated = Notification.Name("notesContentUpdated")
}

class NotesNotification {
    static let contentUpdated = Notification.Name.notesContentUpdated
}
