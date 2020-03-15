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
        
        UserProvider.shared.autoLogin { [weak self] (isLogin) in
            self?.setRootVC(isLogin: isLogin)
        }
        
    }
    
    func setRootVC(isLogin: Bool) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let mainStoryboard = UIStoryboard(name: TTConstant.main, bundle: nil)
        
        if isLogin {
            
            guard let homeVC = mainStoryboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else { return }
            
            appDelegate.window?.rootViewController = homeVC
            
        } else {
            
            guard let loginVC = mainStoryboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else { return }
            
            appDelegate.window?.rootViewController = loginVC
        }
        
    }
}
