//
//  UIImage+Extension.swift
//  Tastopia
//
//  Created by FISH on 2020/1/31.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

enum ImageAsset: String {
    
    case Icon_64px_Itsukushima
    case Icon_32px_Itsukushima
    
    case Icon_512px_Ramen
    
    case Icon_32px_Pin
    case Icon_32px_Phone
    case Icon_32px_Add_User
    case Icon_32px_Photo_Camera
    case Icon_32px_Edit
    case Icon_32px_Left_Arrow
    
    case Image_Cancel
    case Image_32px_Cancel

}

extension UIImage {

    static func asset(_ asset: ImageAsset) -> UIImage? {

        return UIImage(named: asset.rawValue)
    }
}
