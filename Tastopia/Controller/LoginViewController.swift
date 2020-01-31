//
//  ViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/1/30.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import FacebookLogin

class LoginViewController: UIViewController {
    
    @IBOutlet weak var googleButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        googleButton.layer.cornerRadius = 5
        facebookButton.layer.cornerRadius = 5
    }
    
    @IBAction func googleSignInPress(_ sender: Any) {
        googleSignIn()
    }
    
    func googleSignIn() {
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func fbLogin(_ sender: Any) {
        facebookLogin()
    }
    
    func facebookLogin() {
        let loginManager = LoginManager()
        loginManager.logIn(
            permissions: [.publicProfile, .email],
            viewController: self
        ) { result in
            switch result {
            case .cancelled:
                print("fb login cancelled")
            case .failed(let error):
                print("fb login fail: \(error)")
            case .success(_, _, let accessToken):
                print("fb login success")
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
                Auth.auth().signIn(with: credential) { (authResult, error) in
                    if let error = error {
                        print("firebase fb login error: \(error)")
                        return
                    }
                    print("firebase fb login")
                    if let user = authResult?.user, let refreshToken = user.refreshToken {
                        UserDefaults.standard.set(refreshToken, forKey: "firebaseToken")
                        
                    }
                    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    guard let tabBarVC = mainStoryboard.instantiateViewController(identifier: "MainTabBarController") as? UITabBarController else { return }
                    appDelegate.window?.rootViewController = tabBarVC
                    appDelegate.window?.makeKeyAndVisible()
                }
            }
        }
    }
    
}
