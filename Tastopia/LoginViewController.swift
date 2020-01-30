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
//                    if let refreshToken = authResult?.user.refreshToken {
//                        UserDefaults.standard.set(refreshToken, forKey: "firebaseToken")
//                    }
                }
            }
        }
    }
    
    @IBAction func signOutPress(_ sender: Any) {
        signOut()
    }
    
    func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            print("sign out")
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}
