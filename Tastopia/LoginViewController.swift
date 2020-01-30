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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
//        Auth.auth().addStateDidChangeListener { (auth, user) in
//
//        }
    }

    @IBAction func googleSignIn(_ sender: Any) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func facebookLogin(_ sender: Any) {
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
                    print("fb login error: \(error)")
                    return
                  }
                  // User is signed in
                  print("fb login")
                }
            }
        }
    }
    
    @IBAction func signOut(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            print("sign out")
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}
