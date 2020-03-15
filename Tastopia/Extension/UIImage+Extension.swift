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

    case Icon_16px_Dot_Flat
    case Icon_16px_Dot_Flat_Black
    case Icon_64px_Food_Location
    case Icon_128px_Food_Location
    case Icon_64px_Food_Location_Black
    case Icon_128px_Food_Location_Black
    
    case Icon_32px_Pin_Red
    case Icon_32px_Phone_Red
    case Icon_32px_Add_User_Red
    case Icon_32px_Photo_Camera_Red
    case Icon_32px_Edit_Red
    case Icon_32px_Key_Red
    
    case Icon_32px_Time_White
    case Icon_32px_Error_White
    case Icon_32px_Success_White
    
    case Icon_24px_Left_Arrow
    case Icon_24px_Check
    
    case Image_Cancel
    case Image_Uploaded
    case Image_Completed
    case Image_32px_Cancel
    
    case Image_Tastopia_01
    case Image_Tastopia_Placeholder
    case Image_Tastopia_01_square

    // swiftlint:enable identifier_name
}

extension UIImage {

    static func asset(_ asset: ImageAsset) -> UIImage? {

        return UIImage(named: asset.rawValue)
    }
}
