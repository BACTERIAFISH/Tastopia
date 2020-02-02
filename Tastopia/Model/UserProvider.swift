//
//  UserProvider.swift
//  Tastopia
//
//  Created by FISH on 2020/2/2.
//  Copyright © 2020 FISH. All rights reserved.
//

import Firebase
//import GoogleSignIn
//import FacebookLogin
//import AuthenticationServices
//import CryptoKit

class UserProvider {
    
    func login(credential: AuthCredential, name inputName: String?, email inputEmail: String?) {
        
        var name = inputName
        var email = inputEmail
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                print("firebase signIn error: \(error)")
                return
            }
            
            if let user = authResult?.user, let refreshToken = user.refreshToken {
                
                if name == nil {
                    name = user.displayName
                }
                
                if email == nil {
                    email = user.email
                }
                
                if let name = name, let email = email {
                    let userData = UserData(uid: user.uid, name: name, email: email)
                    FirestoreManager.shared.addData(collection: "Users", document: user.uid, data: userData)
                    
                    do {
                        let data = try PropertyListEncoder().encode(userData)
                        UserDefaults.standard.set(data, forKey: "userData")
                    } catch {
                        print("userData encode error: \(error)")
                    }
                }
                
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
