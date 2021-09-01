//
//  TrackStats.swift
//  FitForm
//
//  Created by Paul Williams on 01/09/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//
// Assumes data points at 1hz
//
// NP  https://medium.com/critical-powers/formulas-from-training-and-racing-with-a-power-meter-2a295c661b46

import Foundation

class TrackStats {
    var EWMA = [Double]()
    var average : Double
    var max : Double
    var normalised : Double
    var MA30 = [Double]()

    let EWMALambda = 0.25
    
    init (track : [Double]) {
        average = 0
        max = 0
        normalised = 0    //NP
        EWMA.removeAll()
        MA30.removeAll()
        
        if track.count > 0 {
            
        
            var lastEWMA = track [0]
            var MA30Tot = 0.0 //Total for moving average of 30s
            
            let count = track.count
            var step = 0
            for point in track {
                step += 1
                average = average + (point / Double (count))
                if point > max {
                    max = point
                }
                MA30Tot = MA30Tot + point
                
                //EWMA
                let newEWMA = (lastEWMA * (1 - EWMALambda)) + (point * EWMALambda)
                EWMA.append(newEWMA)
                lastEWMA = newEWMA
                
                //normalised - Create Array of fourth power of moving average
                if step >= 30 {
                    MA30Tot = MA30Tot - track[step-30]
                    let MA30Val = pow (MA30Tot / 30, 4)
                    MA30.append(MA30Val)
                }
                
            }
            
            //normalised - fourth root of average of MA30
            var MA30_Avg = 0.0
            for val in MA30 {
                MA30_Avg += val / Double(MA30.count)
            }
            normalised = pow(MA30_Avg, 0.25)
            
          //  print ("track = \(track)")
         //   print ("average = \(average)")
         //   print ("maximum = \(max)")
        //    print ("normalised = \(normalised)")
           // print ("EWMA = \(EWMA)")
        }
    } //init
    
    
}
