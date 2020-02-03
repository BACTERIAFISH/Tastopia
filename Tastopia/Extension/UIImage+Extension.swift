//
//  UIImage+Extension.swift
//  Tastopia
//
//  Created by FISH on 2020/1/31.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

enum ImageAsset: String {
    
    case itsukushima_16
    case Icon_64px_Itsukushima
    case Icon_32px_Itsukushima
    
    case Icon_32px_Star_Circle
    case Icon_32px_Address_Pin
    case Icon_32px_Phone_Call
    case Icon_32px_Person_Circle
    case Icon_32px_Camera
    case Icon_32px_Pencil

}

extension UIImage {

    static func asset(_ asset: ImageAsset) -> UIImage? {

        return UIImage(named: asset.rawValue)
    }
}
