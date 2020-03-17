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
        
        if isLogin {
            
            let homeStoryboard = UIStoryboard(name: TTConstant.StoryboardName.home, bundle: nil)
            
            guard let homeVC = homeStoryboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else { return }
            
            appDelegate.window?.rootViewController = homeVC
            
        } else {
            
            let loginStoryboard = UIStoryboard(name: TTConstant.StoryboardName.login, bundle: nil)
            
            guard let loginVC = loginStoryboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else { return }
            
            appDelegate.window?.rootViewController = loginVC
        }
        
    }
}
