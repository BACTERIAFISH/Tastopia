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
    var userTasks = [TaskData]()
    var agreeWritings = [String]()
    var disagreeWritings = [String]()
    var responseWritings = [String]()
    
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
            checkCommentWritings()
            
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
                    let docRef = FirestoreManager.shared.db.collection("Users").document(user.uid)
                    FirestoreManager.shared.addCustomData(docRef: docRef, data: userData)
                    
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
                    self?.checkCommentWritings()
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

        guard let uid = uid else { return }
        
        FirestoreManager.shared.readData(collection: "Users", document: uid) { [weak self] (result) in
            guard let uid = self?.uid else { return }
            switch result {
            case .success(let data):
                if let number = data["taskNumber"] as? Int {
                    self?.taskNumber = number
                } else {
                    self?.taskNumber = 0
                    let data = ["taskNumber": 0]
                    let docRef = FirestoreManager.shared.db.collection("Users").document(uid)
                    FirestoreManager.shared.addData(docRef: docRef, data: data)
                }
                self?.checkUserTasks()
                NotificationCenter.default.post(name: NSNotification.Name("taskNumber"), object: nil)
            case .failure(let error):
                print("FirestoreManager checkTaskNumber error: \(error)")
            }
        }
    }
    
    func checkUserTasks() {
        
        guard let uid = uid, let taskNumber = taskNumber else { return }
        
        let ref = FirestoreManager.shared.db.collection("Users").document(uid).collection("Tasks").order(by: "restaurantNumber")
        
        ref.getDocuments { [weak self] (query, error) in
            if let error = error {
                print("checkUserTasks error: \(error)")
                return
            } else {
                if query!.documents.count > 0 {
                    for doc in query!.documents {
                        let result = Result {
                            try doc.data(as: TaskData.self)
                        }
                        
                        switch result {
                        case .success(let task):
                            if let task = task {
                                self?.userTasks.append(task)
                            }
                        case .failure(let error):
                            print("checkUserTasks decode error: \(error)")
                        }
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("userTasks"), object: nil)
                } else {
                    self?.getTaskTypes(completion: { (result) in
                        switch result {
                        case .success(let taskTypes):
                            var tasks = [TaskData]()
                            for i in 0..<taskNumber + 3 {
                                guard let taskType = taskTypes.randomElement() else { return }
                                let task = TaskData(restaurantNumber: i, people: taskType.people, media: taskType.media, composition: taskType.composition)
                                tasks.append(task)
                                let ref = FirestoreManager.shared.db.collection("Users").document(uid).collection("Tasks").document()
                                FirestoreManager.shared.addCustomData(docRef: ref, data: task)
                            }
                            self?.userTasks = tasks
                            NotificationCenter.default.post(name: NSNotification.Name("userTasks"), object: nil)
                        case .failure(let error):
                            print("getTaskTypes error: \(error)")
                        }
                    })
                    
                }
                
            }
        }
    }
    
    func getTaskTypes(completion: @escaping (Result<[TaskType], Error>) -> Void) {
        let ref = FirestoreManager.shared.db.collection("TaskTypes")
        
        ref.getDocuments { (query, error) in
            if let error = error {
                completion(Result.failure(error))
                return
            } else {
                var taskTypes = [TaskType]()
                for doc in query!.documents {
                    let result = Result {
                        try doc.data(as: TaskType.self)
                    }
                    
                    switch result {
                    case .success(let taskType):
                        if let taskType = taskType {
                            taskTypes.append(taskType)
                        }
                    case .failure(let error):
                        print("checkUserTasks decode error: \(error)")
                    }
                }
                completion(Result.success(taskTypes))
            }
        }
    }
    
    func checkCommentWritings() {
        
        guard let uid = uid else { return }
        
        FirestoreManager.shared.readData(collection: "Users", document: uid) { [weak self] (result) in
            switch result {
            case .success(let data):
                if let writings = data["agreeWritings"] as? [String] {
                    self?.agreeWritings = writings
                }
                if let writings = data["disagreeWritings"] as? [String] {
                    self?.disagreeWritings = writings
                }
                if let writings = data["responseWritings"] as? [String] {
                    self?.responseWritings = writings
                }
            case .failure(let error):
                print("FirestoreManager checkCommentWritings error: \(error)")
            }
        }
    }
    
}

struct TaskData: Codable {
    let restaurantNumber: Int
    let people: Int
    let media: Int
    let composition: Int
}

struct TaskType: Codable {
    let documentID: String
    let people: Int
    let media: Int
    let composition: Int
}
