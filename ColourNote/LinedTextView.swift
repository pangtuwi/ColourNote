//
//  LinedTextView based on efrt RoundUIView.swift
//
//  Created by Paul Williams on 14/10/2018.
//  Copyright © 2018 Paul Williams. All rights reserved.
//
// https://stackoverflow.com/questions/46713603/round-corners-uiview-in-swift-4
//https://stackoverflow.com/questions/25591389/uiview-with-shadow-rounded-corners-and-custom-drawrect

import UIKit

@IBDesignable
class LinedTextView: UITextView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    @IBInspectable var shadow: Bool {
        get {
            return layer.shadowOpacity > 0.0
        }
        set {
            if newValue == true {
                self.addShadow()
            }
        }
    }
    
    
    @IBInspectable var borderColor: UIColor = UIColor.white {
        didSet {
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 2.0 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            self.layer.cornerRadius = cornerRadius
        }
    }

    func addShadow(shadowColor: CGColor = UIColor.black.cgColor,
                   shadowOffset: CGSize = CGSize(width:0, height: 1.0),
                   shadowOpacity: Float = 0.4,
                   shadowRadius: CGFloat = 1) {
        layer.shadowColor = shadowColor
        layer.shadowOffset = shadowOffset
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = shadowRadius
    }
    
    //https://stackoverflow.com/questions/41486123/how-to-make-multi-lined-underlined-uitextview-uitextfield
    
    var lineHeight: CGFloat = 32//13.8

    
     override var font: UIFont? {
       didSet {
         if let newFont = font {
           lineHeight = newFont.lineHeight+1
         }
       }
     }

     override func draw(_ rect: CGRect) {
       let ctx = UIGraphicsGetCurrentContext()
       ctx?.setStrokeColor(UIColor.lightGray.cgColor)
       let numberOfLines = Int(rect.height / lineHeight)
       let topInset = textContainerInset.top

       for i in 1...numberOfLines {
         let y = topInset + CGFloat(i) * lineHeight

         let line = CGMutablePath()
         line.move(to: CGPoint(x: 0.0, y: y))
         line.addLine(to: CGPoint(x: rect.width, y: y))
         ctx?.addPath(line)
       }

       ctx?.strokePath()

       super.draw(rect)
     }
    
    
}
