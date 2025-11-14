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
    static let EFRT_BKGREY = UIColor.systemGroupedBackground
    
    //Use screen capture from Android Colornote and....
    //https://www.ralfebert.de/ios-examples/uikit/swift-uicolor-picker/
    //https://www.ginifab.com/feeds/pms/color_picker_from_image.php
    
    static let CN_COLORS = [UIColor(hue: 0, saturation: 0, brightness: 1, alpha: 1.0) /* #ffffff */,
                            UIColor(hue: 0.9861, saturation: 0.52, brightness: 0.96, alpha: 1.0),
                            UIColor(hue: 0.0806, saturation: 0.67, brightness: 0.99, alpha: 1.0), /* #fea853 */
                            UIColor(hue: 0.1333, saturation: 0.58, brightness: 0.96, alpha: 1.0), /* #f5da65 */
                            UIColor(hue: 0.2611, saturation: 0.51, brightness: 0.83, alpha: 1.0), /* #96d467 */
                            UIColor(hue: 0.6194, saturation: 0.48, brightness: 1, alpha: 1.0), /* #83a5ff */
                            UIColor(hue: 0.75, saturation: 0.39, brightness: 0.87, alpha: 1.0), /* #b387de */
                            UIColor(hue: 0, saturation: 0, brightness: 0.2, alpha: 1.0), /* #333333 */
                            UIColor(hue: 0, saturation: 0, brightness: 0.8, alpha: 1.0), /* #cccccc */
                            UIColor(hue: 0, saturation: 0, brightness: 0.94, alpha: 1.0)] /* #f0f0f0 */
    
    //Light colors - drop saturation only (bit of a guess)
    static let CN_LIGHT_COLORS = [UIColor(hue: 0, saturation: 0, brightness: 1, alpha: 1.0) /* #ffffff */,
                            UIColor(hue: 0.9861, saturation: 0.06, brightness: 0.96, alpha: 1.0),
                            UIColor(hue: 0.0806, saturation: 0.15, brightness: 1, alpha: 1.0), /* #ffebd8 */
                            UIColor(hue: 0.1333, saturation: 0.15, brightness: 0.96, alpha: 1.0),
                            UIColor(hue: 0.2611, saturation: 0.15, brightness: 0.83, alpha: 1.0),
                            UIColor(hue: 0.6194, saturation: 0.15, brightness: 1, alpha: 1.0),
                            UIColor(hue: 0.75, saturation: 0.15, brightness: 0.87, alpha: 1.0),
                            UIColor(hue: 0, saturation: 0, brightness: 0.4, alpha: 1.0),
                            UIColor(hue: 0, saturation: 0, brightness: 0.9, alpha: 1.0),
                            UIColor(hue: 0, saturation: 0, brightness: 0.99, alpha: 1.0)]
    
 
    
    //Temporary Variables
    var LastTCXFileName : String
    var activityIDToDisplay : Int = 0
    var noteIDToDisplay : Int = 0
    
    private init() { //This prevents others from using the default '()' initializer for this class.
        LastTCXFileName = ""
    }
    
}





