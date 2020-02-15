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
    
    var userData: UserData?
    var userTasks = [TaskData]()
    
//    var uid: String?
//    var name: String?
//    var email: String?
//    var taskNumber: Int?
//    var passRestaurantNumbers = [Int]()
//    
//    var agreeWritings = [String]()
//    var disagreeWritings = [String]()
//    var responseWritings = [String]()
    
    private init() {}
    
    func autoLogin() {
        if UserDefaults.standard.string(forKey: "firebaseToken") != nil {
            guard let uid = Auth.auth().currentUser?.uid else { return }
//            guard let uid = UserDefaults.standard.string(forKey: "uid") else { return }
            
            FirestoreManager.shared.readCustomData(collection: "Users", document: uid, dataType: UserData.self) { [weak self] (result) in
                switch result {
                case .success(let userData):
                    self?.userData = userData
                    
                    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    guard let tabBarVC = mainStoryboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController else { return }
                    appDelegate.window?.rootViewController = tabBarVC
                    
                case .failure(let error):
                    print("autoLogin error: \(error)")
                }
            }
//            guard
//                let data = UserDefaults.standard.object(forKey: "userData") as? Data,
//                let userData = try? PropertyListDecoder().decode(UserData.self, from: data)
//                else { return }
            
//            uid = userData.uid
//            name = userData.name
//            email = userData.email
            
//            checkTaskNumber()
//            checkCommentWritings()
            
//            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
//            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
//            guard let tabBarVC = mainStoryboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController else { return }
//            appDelegate.window?.rootViewController = tabBarVC
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
                
                if let name = name, let email = email { FirestoreManager.shared.db.collection("Users").document(user.uid).setData(["name": name], merge: true)

                    FirestoreManager.shared.readCustomData(collection: "Users", document: user.uid, dataType: UserData.self) { [weak self] (result) in
                        switch result {
                        case .success(let userData):
                            self?.userData = userData
                            
//                            NotificationCenter.default.post(name: NSNotification.Name("taskNumber"), object: nil)
                            
                            self?.checkUserTasks()
                            
                        case .failure(_):
                            let userData = UserData(uid: user.uid, name: name, email: email)
                            self?.userData = userData
                            do {
                                try FirestoreManager.shared.db.collection("Users").document(user.uid).setData(from: userData)
                                
//                                NotificationCenter.default.post(name: NSNotification.Name("taskNumber"), object: nil)
                                
                                self?.checkUserTasks()
                                
                            } catch {
                                print("login create new user error: \(error)")
                            }
                        }
                        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        guard let tabBarVC = mainStoryboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController else { return }
                        appDelegate.window?.rootViewController = tabBarVC
                    }
//                    let userData = UserData(uid: user.uid, name: name, email: email)
//                    let docRef = FirestoreManager.shared.db.collection("Users").document(user.uid)
//                    FirestoreManager.shared.addCustomData(docRef: docRef, data: userData)
                    
//                    do {
//                        let data = try PropertyListEncoder().encode(userData)
//                        UserDefaults.standard.set(data, forKey: "userData")
//                    } catch {
//                        print("userData encode error: \(error)")
//                    }
                    
//                    self?.uid = user.uid
//                    self?.name = name
//                    self?.email = email
//
//                    self?.checkTaskNumber()
//                    self?.checkCommentWritings()
                }
//                UserDefaults.standard.set(user.uid, forKey: "uid")
//                UserDefaults.standard.set(refreshToken, forKey: "firebaseToken")
                
            }
            
//            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
//            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
//            guard let tabBarVC = mainStoryboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController else { return }
//            appDelegate.window?.rootViewController = tabBarVC
            //            appDelegate.window?.makeKeyAndVisible()
        }
    }
    
//    func checkTaskNumber() {
//
//        guard let uid = uid else { return }
//
//        FirestoreManager.shared.readData(collection: "Users", document: uid) { [weak self] (result) in
//            guard let uid = self?.uid else { return }
//            switch result {
//            case .success(let data):
//                if let number = data["taskNumber"] as? Int {
//                    self?.taskNumber = number
//                } else {
//                    self?.taskNumber = 0
//                    let data = ["taskNumber": 0]
//                    let docRef = FirestoreManager.shared.db.collection("Users").document(uid)
//                    FirestoreManager.shared.addData(docRef: docRef, data: data)
//                }
//                self?.checkUserTasks()
//                NotificationCenter.default.post(name: NSNotification.Name("taskNumber"), object: nil)
//            case .failure(let error):
//                print("FirestoreManager checkTaskNumber error: \(error)")
//            }
//        }
//    }
    
    func checkUserTasks() {
        
        guard let userData = userData else {
            return
        }
        
        let ref = FirestoreManager.shared.db.collection("Users").document(userData.uid).collection("Tasks").order(by: "restaurantNumber")
        
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
                            for i in 0..<userData.taskNumber + 3 {
                                guard let taskType = taskTypes.randomElement() else { return }
                                let ref = FirestoreManager.shared.db.collection("Users").document(userData.uid).collection("Tasks").document()
                                let task = TaskData(documentID: ref.documentID, restaurantNumber: i, people: taskType.people, media: taskType.media, composition: taskType.composition, status: 0, taskID: ref.documentID)
                                tasks.append(task)
                                
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
    
//    func checkCommentWritings() {
//        
//        guard let uid = uid else { return }
//        
//        FirestoreManager.shared.readData(collection: "Users", document: uid) { [weak self] (result) in
//            switch result {
//            case .success(let data):
//                if let writings = data["agreeWritings"] as? [String] {
//                    self?.agreeWritings = writings
//                }
//                if let writings = data["disagreeWritings"] as? [String] {
//                    self?.disagreeWritings = writings
//                }
//                if let writings = data["responseWritings"] as? [String] {
//                    self?.responseWritings = writings
//                }
//            case .failure(let error):
//                print("FirestoreManager checkCommentWritings error: \(error)")
//            }
//        }
//    }
    
//    func getUserData() {
//        guard let uid = uid else { return }
//
//        FirestoreManager.shared.readCustomData(collection: "Users", document: uid, dataType: AllUserData.self) { (result) in
//            switch result {
//            case .success(let userData):
//                print(userData)
//            case .failure(let error):
//                print(error)
//            }
//        }
//    }
}

struct UserData: Codable {
    let uid: String
    let name: String
    let email: String
    var taskNumber: Int = 0
    var agreeWritings: [String] = []
    var disagreeWritings: [String] = []
    var responseWritings: [String] = []
    var passRestaurant: [Int] = []
}

//struct UserData: Codable {
//    let uid: String
//    let name: String
//    let email: String
//}

struct TaskData: Codable {
    let documentID: String
    let restaurantNumber: Int
    let people: Int
    let media: Int
    let composition: Int
    var status: Int // 0, 1, 2, 3
    var taskID: String
}

struct TaskType: Codable {
    let documentID: String
    let people: Int
    let media: Int
    let composition: Int
}
