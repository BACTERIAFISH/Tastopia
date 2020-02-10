//
//  UIColor+Extension.swift
//  Tastopia
//
//  Created by FISH on 2020/1/30.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

private enum TTColor: String {

    case SUMI
    
    case HAI
    
    case HAIZAKURA
    
    case SAKURA
    
    case SHIRONERI
}

extension UIColor {

    static let SUMI = TTColor(.SUMI)
    
    static let HAI = TTColor(.HAI)
    
    static let SHIRONERI = TTColor(.SHIRONERI)
    
    static let HAIZAKURA = TTColor(.HAIZAKURA)
    
    static let SAKURA = TTColor(.SAKURA)
    
    private static func TTColor(_ color: TTColor) -> UIColor? {

        return UIColor(named: color.rawValue)
    }

    static func hexStringToUIColor(hex: String) -> UIColor {

        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        if (cString.count) != 6 {
            return UIColor.HAI!
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
