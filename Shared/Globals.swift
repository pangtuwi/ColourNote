//
//  Globals.swift
//  FitForm
//
//  Created by Paul Williams on 25/08/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//


import Foundation
import UIKit


class Globals{
    static let sharedInstance = Globals()

    //Colours
    static let EFRT_RED = UIColor(red: 215/255, green: 100/255, blue: 54/255, alpha: 1)
    static let EFRT_GREEN = UIColor(red: 148/255, green: 191/255, blue: 84/255, alpha: 1)
    static let EFRT_BLUE = UIColor(red: 104/255, green: 192/255, blue: 226/255, alpha: 1)
    static let EFRT_ORANGE = UIColor(red: 240/255, green: 176/255, blue: 66/255, alpha: 1)
    static let EFRT_LTGREY = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1)
    static let EFRT_DKGREY = UIColor(red: 20/255, green: 20/255, blue: 20/255, alpha: 1)
    static let EFRT_BKGREY = UIColor.groupTableViewBackground
    
    //Temporary Variables
    var LastTCXFileName : String
    var activityIDToDisplay : Int = 0
    var noteIDToDisplay : Int = 0
    
    private init() { //This prevents others from using the default '()' initializer for this class.
        LastTCXFileName = ""
    }
    
}





