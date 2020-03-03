//
//  LaunchViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/16.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class LaunchViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserProvider.shared.autoLogin()
    }
    
}
