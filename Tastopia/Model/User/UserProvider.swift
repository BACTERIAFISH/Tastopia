//
//  UserProvider.swift
//  Tastopia
//
//  Created by FISH on 2020/2/2.
//  Copyright © 2020 FISH. All rights reserved.
//

import Firebase

class UserProvider {
    
    static let shared = UserProvider()
    
    var userData: UserData?
    
    private let firestoreManager = FirestoreManager()
    private let firestoreReference = FirestoreReference()
    private let firestoreParser = FirestoreParser()
    
    private init() {}
    
    private func operation(_ operation: (UserData) -> Void) {
        
        guard let user = userData else {
            return
        }
        
        operation(user)
    }
    
    func autoLogin(completion: @escaping (Bool) -> Void) {
        
        if let user = Auth.auth().currentUser {
            
            getUserData(uid: user.uid, name: nil, credential: nil) { (gotUserData) in
                if gotUserData {
                    completion(true)
                } else {
                    completion(false)
                }
            }
            
        } else {
            
            completion(false)
        }
        
    }
    
    func login(credential: AuthCredential, name inputName: String?, email inputEmail: String?, completion: @escaping (Bool) -> Void) {
        
        Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in

            if let error = error {
                print("firebase signIn error: \(error)")
                return
            }
            
            guard
                let strongSelf = self,
                let user = authResult?.user,
                let name = inputName ?? user.displayName,
                let email = inputEmail ?? user.email
                else { return }
            
            strongSelf.getUserData(uid: user.uid, name: name, credential: credential) { (gotUserData) in
                
                if gotUserData {
                    
                    completion(true)
                    
                } else {
                    
                    strongSelf.registerUser(uid: user.uid, name: name, email: email) { (isRegistered) in
                        
                        if isRegistered {
                            
                            completion(true)
                            
                        } else {
                            
                            completion(false)
                        }
                    }
                    
                }
            }
        }
        
    }
    
    func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            
            UserDefaults.standard.removeObject(forKey: TTConstant.UserDefaultKey.userStatus)
            
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    private func getUserData(uid: String, name: String?, credential: AuthCredential?, completion: @escaping (Bool) -> Void) {
        
        firestoreManager.readData(firestoreReference.usersDocumentRef(doc: uid)) { [weak self] (result) in
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let snapshot):
                strongSelf.firestoreParser.parseDocument(decode: snapshot, from: UserData.self) { (result) in
                    
                    switch result {
                    case .success(var user):
                        
                        if let credential = credential, credential.provider != TTConstant.appleCom, let name = name, name != user.name {
                            
                            let ref = strongSelf.firestoreReference.usersDocumentRef(doc: user.uid)
                            
                            ref.setData([FirestoreReference.FieldKey.name: name], merge: true)
                            
                            user.name = name
                        }
                        
                        strongSelf.userData = user
                        TaskProvider.shared.checkUserTasks(userData: strongSelf.userData)
                        
                        completion(true)
                        
                    case .failure(let error):
                        
                        print("FirestoreParser parseDocument error: \(error)")
                    
                        completion(false)
                    }
                }
            case .failure(let error):
                print("FirestoreManager readData error: \(error)")
                completion(false)
            }
        }
    }
    
    private func registerUser(uid: String, name: String, email: String, completion: @escaping (Bool) -> Void) {
        
        firestoreManager.uploadImage(image: UIImage.asset(.Image_Tastopia_01)!, fileName: uid) { [weak self] (result) in
            
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let urlString):

                let userData = UserData(uid: uid, name: name, email: email, imagePath: urlString)
                
                strongSelf.userData = userData
                
                do {
                    let ref = strongSelf.firestoreReference.usersDocumentRef(doc: uid)
                    try ref.setData(from: userData)

                    TaskProvider.shared.checkUserTasks(userData: strongSelf.userData)
                    
                    completion(true)

                } catch {
                    print("registerUser create new user error: \(error)")
                    completion(false)
                }
            case .failure(let error):
                print("registerUser upload image error: \(error)")
                completion(false)
            }
        }
    }
    
    func checkWhetherAddMoreTask(task: TaskData) {
        
        operation({ user in
            
            if !user.passRestaurant.contains(task.restaurantNumber) {
                
                TaskProvider.shared.addMoreTask()
                
                addPassRestaurantTaskNumber(task: task)
            }
        })
        
    }
    
    private func addPassRestaurantTaskNumber(task: TaskData) {
        
        operation({ user in
            
            userData?.passRestaurant.append(task.restaurantNumber)
            userData?.taskNumber += 1
            
            let ref = firestoreReference.usersDocumentRef(doc: user.uid)
            
            firestoreManager.addData(docRef: ref, data: [
                FirestoreReference.FieldKey.taskNumber: user.taskNumber + 1,
                FirestoreReference.FieldKey.passRestaurant: FieldValue.arrayUnion([task.restaurantNumber])
            ])
            
        })
    }
    
}
