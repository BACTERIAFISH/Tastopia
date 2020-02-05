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
    
    static let shared = UserProvider()
    
    var uid: String?
    var name: String?
    var email: String?
    var taskNumber: Int?
    
    private init() {}
    
    func autoLogin() {
        if UserDefaults.standard.string(forKey: "firebaseToken") != nil {
            
            guard
                let data = UserDefaults.standard.object(forKey: "userData") as? Data,
                let userData = try? PropertyListDecoder().decode(UserData.self, from: data)
            else { return }
            
            uid = userData.uid
            name = userData.name
            email = userData.email
            
            checkTaskNumber()
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            guard let tabBarVC = mainStoryboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController else { return }
            appDelegate.window?.rootViewController = tabBarVC
//            appDelegate.window?.makeKeyAndVisible()
        }
    }
    
    func login(credential: AuthCredential, name inputName: String?, email inputEmail: String?) {
        
        var name = inputName
        var email = inputEmail
        
        Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
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
                    FirestoreManager.shared.addCustomData(collection: "Users", document: user.uid, data: userData)
                    
                    do {
                        let data = try PropertyListEncoder().encode(userData)
                        UserDefaults.standard.set(data, forKey: "userData")
                    } catch {
                        print("userData encode error: \(error)")
                    }
                    
                    self?.uid = user.uid
                    self?.name = name
                    self?.email = email
                    
                    self?.checkTaskNumber()
                }
                
                UserDefaults.standard.set(refreshToken, forKey: "firebaseToken")
                
            }
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            guard let tabBarVC = mainStoryboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController else { return }
            appDelegate.window?.rootViewController = tabBarVC
//            appDelegate.window?.makeKeyAndVisible()
        }
    }

    func checkTaskNumber() {
//        guard
//            let data = UserDefaults.standard.object(forKey: "userData") as? Data,
//            let userData = try? PropertyListDecoder().decode(UserData.self, from: data)
//        else { return }
        guard let uid = uid else { return }
        
        FirestoreManager.shared.readData(collection: "Users", document: uid) { [weak self] (result) in
            switch result {
            case .success(let data):
                if let number = data["taskNumber"] as? Int {
                    self?.taskNumber = number
                } else {
                    self?.taskNumber = 0
                    let data = ["taskNumber": 0]
                    FirestoreManager.shared.addData(collection: "Users", document: self?.uid, data: data)
                }
                NotificationCenter.default.post(name: NSNotification.Name("taskNumber"), object: nil)
            case .failure(let error):
                print("FirestoreManager readData error: \(error)")
            }
        }
    }
    
}
