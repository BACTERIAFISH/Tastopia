//
//  UIImage+Extension.swift
//  Tastopia
//
//  Created by FISH on 2020/1/31.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

enum ImageAsset: String {
    
    // swiftlint:disable identifier_name
    
    case itsukushima_16
    case Icon_64px_Itsukushima
    case Icon_32px_Itsukushima
    
    // swiftlint:enable identifier_name
}

extension UIImage {

    static func asset(_ asset: ImageAsset) -> UIImage? {

        return UIImage(named: asset.rawValue)
    }
}
