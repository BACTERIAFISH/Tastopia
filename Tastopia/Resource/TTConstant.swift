//
//  TTConstant.swift
//  Tastopia
//
//  Created by FISH on 2020/3/4.
//  Copyright © 2020 FISH. All rights reserved.
//

import Foundation

struct TTConstant {
    
    static let main = "Main"
    
    static let photo = "相片"
    
    static let video = "影片"
    
    static let appleCom = "apple.com"
    
    struct UserDefaultKey {
        
        static let userStatus = "userStatus"
    }
    
    struct NotificationName {
        
        static let userTasks = NSNotification.Name("userTasks")

        static let addRestaurant = NSNotification.Name("addRestaurant")
    }

    struct ViewControllerID {
        
        static let profileViewController = "ProfileViewController"
        
        static let taskContentViewController = "TaskContentViewController"
        
        static let taskRecordNavigationController = "TaskRecordNavigationController"
        
        static let qrCodeScanViewController = "QRCodeScanViewController"
    }
    
}
