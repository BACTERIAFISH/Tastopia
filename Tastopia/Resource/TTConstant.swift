//
//  TTConstant.swift
//  Tastopia
//
//  Created by FISH on 2020/3/4.
//  Copyright © 2020 FISH. All rights reserved.
//

import Foundation

struct TTConstant {
    
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
    
    struct StoryboardName {
        
        static let main = "Main"
        
        static let login = "Login"
        
        static let task = "Task"
        
        static let qrcode = "QRCode"
        
        static let media = "Media"
        
        static let record = "Record"
        
        static let profile = "Profile"
    }

    struct ViewControllerID {
        
        static let profileViewController = "ProfileViewController"
        
        static let taskContentViewController = "TaskContentViewController"
        
        static let taskRecordNavigationController = "TaskRecordNavigationController"
        
        static let qrCodeScanViewController = "QRCodeScanViewController"
        
        static let selectImageViewController = "SelectImageViewController"
        
        static let recordContentViewController = "RecordContentViewController"
    }
    
    struct CellIdentifier {
        
        static let recordContentTopTableViewCell = "RecordContentTopTableViewCell"
        
        static let recordContentImageTableViewCell = "RecordContentImageTableViewCell"
        
        static let recordContentCompositionTableViewCell = "RecordContentCompositionTableViewCell"
        
        static let recordContentAgreeTableViewCell = "RecordContentAgreeTableViewCell"
        
        static let executeTaskPhotoCollectionViewCell = "ExecuteTaskPhotoCollectionViewCell"
        
        static let executeTaskAddCollectionViewCell = "ExecuteTaskAddCollectionViewCell"
        
        static let taskRecordCollectionViewCell = "TaskRecordCollectionViewCell"
    }
    
}
