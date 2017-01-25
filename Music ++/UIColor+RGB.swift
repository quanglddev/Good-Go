//
//  UIColor+RGB.swift
//  Smart Calender (Beta)
//
//  Created by QUANG on 12/21/16.
//  Copyright © 2016 Q.U.A.N.G. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        let newRed = CGFloat(red)/255
        let newGreen = CGFloat(green)/255
        let newBlue = CGFloat(blue)/255
        
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }
}
