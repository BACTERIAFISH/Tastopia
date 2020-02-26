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
    var userTasks = [TaskData]()
    
    private init() {}
    
    func autoLogin() {
        
        if let uid = UserDefaults.standard.string(forKey: "uid") {
            FirestoreManager.shared.readCustomData(collection: "Users", document: uid, dataType: UserData.self) { [weak self] (result) in
                switch result {
                case .success(let userData):
                    self?.userData = userData
                    self?.checkUserTasks()
                    
                    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    guard let homeVC = mainStoryboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else { return }
                    appDelegate.window?.rootViewController = homeVC
                    
                case .failure(let error):
                    print("autoLogin error: \(error)")
                }
            }
        } else {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            guard let loginVC = mainStoryboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else { return }
            appDelegate.window?.rootViewController = loginVC
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
            
            if let user = authResult?.user {
                
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
                            self?.checkUserTasks()
                            
                        case .failure(_):
                            let userData = UserData(uid: user.uid, name: name, email: email)
                            self?.userData = userData
                            do {
                                try FirestoreManager.shared.db.collection("Users").document(user.uid).setData(from: userData)
                                
                                self?.checkUserTasks()
                                
                            } catch {
                                print("login create new user error: \(error)")
                            }
                        }
                        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        guard let homeVC = mainStoryboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else { return }
                        appDelegate.window?.rootViewController = homeVC
                    }
                }
                
                UserDefaults.standard.set(user.uid, forKey: "uid")
            }
        }
    }
    
    func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            print("sign out")
            
            UserDefaults.standard.removeObject(forKey: "uid")
            UserDefaults.standard.removeObject(forKey: "userStatus")
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else { return }
            
            appDelegate.window?.rootViewController = loginVC
            
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
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
                            for index in 0..<userData.taskNumber + 3 {
                                guard let taskType = taskTypes.randomElement() else { return }
                                let ref = FirestoreManager.shared.db.collection("Users").document(userData.uid).collection("Tasks").document()
                                let task = TaskData(documentID: ref.documentID, restaurantNumber: index, people: taskType.people, media: taskType.media, composition: taskType.composition, status: 0, taskID: ref.documentID)
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

struct TaskData: Codable {
    let documentID: String
    let restaurantNumber: Int
    let people: Int
    let media: Int
    let composition: Int
    var status: Int // 0, 1, 2
    var taskID: String
}

struct TaskType: Codable {
    let documentID: String
    let people: Int
    let media: Int
    let composition: Int
}
