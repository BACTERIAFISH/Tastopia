//
//  CALayer+Extension.swift
//  Tastopia
//
//  Created by FISH on 2020/2/11.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

extension CALayer {
    func createTTShadow(
        color: CGColor = UIColor.SUMI!.cgColor,
        offset: CGSize = CGSize(width: 0, height: 5),
        radius: CGFloat = 5,
        opacity: Float = 0.3
    ) {
        shadowColor = color
        shadowOffset = offset
        shadowRadius = radius
        shadowOpacity = opacity
    }
    
    func createTTBorder(
        width: CGFloat = 3,
        color: CGColor = UIColor.SAKURA!.cgColor
    ) {
        borderWidth = width
        borderColor = color
    }
}
