//
//  TaskProvider.swift
//  Tastopia
//
//  Created by FISH on 2020/3/7.
//  Copyright © 2020 FISH. All rights reserved.
//

import Foundation

class TaskProvider {
    
    static let shared = TaskProvider()
    
    var userTasks = [TaskData]()
    
    private let firestoreManager = FirestoreManager()
    private let firestoreReference = FirestoreReference()
    private let firestoreParser = FirestoreParser()
    
    private init() {}
    
    func checkUserTasks(userData: UserData?) {
        
        guard let userData = userData else { return }
        
        let ref = firestoreReference.usersTasksCollectionRef(doc: userData.uid)
        
        firestoreManager.readData(ref) { [weak self] (result) in
            
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let snapshot):
                
                if snapshot!.documents.count > 0 {
                    
                    strongSelf.firestoreParser.parseDocuments(decode: snapshot, from: TaskData.self) { (result) in
                        
                        switch result {
                        case .success(let taskDataArr):
                            
                            strongSelf.userTasks = taskDataArr
                            
                            NotificationCenter.default.post(name: TTConstant.NotificationName.userTasks, object: nil)
                            
                        case .failure(let error):
                            
                            print("checkUserTasks error: \(error)")
                        }
                    }
                    
                } else {
                    
                    strongSelf.createUserTasks(userData: userData)

                }
            case .failure(let error):
                
                print("checkUserTasks error: \(error)")
            }
        }
        
    }
    
    private func createUserTasks(userData: UserData) {
        
        getTaskTypes { [weak self] (result) in
            
            guard let strongSelf = self else { return }
            
            switch result {
                
            case .success(let taskTypes):
                
                var tasks = [TaskData]()
                
                for index in 0..<userData.taskNumber + 3 {
                    
                    guard let taskType = taskTypes.randomElement() else { return }
                    
                    let ref = strongSelf.firestoreReference.newUsersTasksDocumentRef(doc: userData.uid)
                    
                    let task = TaskData(documentID: ref.documentID, restaurantNumber: index, people: taskType.people, media: taskType.media, composition: taskType.composition, status: 0, taskID: ref.documentID)
                    
                    tasks.append(task)
                    
                    strongSelf.firestoreManager.addCustomData(docRef: ref, data: task)
                }
                
                strongSelf.userTasks = tasks
                
                NotificationCenter.default.post(name: TTConstant.NotificationName.userTasks, object: nil)
                
            case .failure(let error):
                
                print("ceateUserTasks error: \(error)")
            }
        }
    }
    
    func getTaskTypes(completion: @escaping (Result<[TaskType], Error>) -> Void) {
        
        let ref = firestoreReference.taskTypesCollectionRef()
        
        firestoreParser.parseDocuments(decode: ref, from: TaskType.self) { (result) in
            
            switch result {
            case .success(let taskTypes):
                
                completion(Result.success(taskTypes))
                
            case .failure(let error):
                
                completion(Result.failure(error))
            }
        }
    }
    
    func changeTaskID(with newTaskID: String, in task: TaskData) {
        
        guard let user = UserProvider.shared.userData else { return }
        
        let ref = firestoreReference.usersTasksDocumentRef(userPath: user.uid, taskPath: task.documentID)
        
        ref.updateData([FirestoreReference.FieldKey.taskID: newTaskID])
        
        for index in 0..<userTasks.count where userTasks[index].taskID == task.taskID {
            userTasks[index].taskID = newTaskID
        }
    }
    
    func checkIsTaskPassed(task: TaskData, completion: @escaping (Result<Bool, Error>) -> Void) {
        
        if task.restaurantNumber == 0 {
            changeTaskStatus(task: task)
            completion(Result.success(true))
            return
        }
        
        let ref = firestoreReference.writingsQuery(isEqualTo: task.taskID)
        
        firestoreManager.readData(ref) { [weak self] (result) in
            switch result {
                
            case .success(let snapshot):
                
                self?.firestoreParser.parseDocuments(decode: snapshot, from: WritingData.self) { (result) in
                    
                    switch result {
                        
                    case .success(var writings):
                        
                        writings = writings.filter({ $0.number == task.restaurantNumber })
                        
                        if writings.count < task.people {
                            completion(Result.success(false))
                            return
                        }
                        
                        var uidSet = Set<String>()
                        
                        for writing in writings {
                            uidSet.insert(writing.uid)
                        }
                        
                        if uidSet.count < task.people {
                            completion(Result.success(false))
                            return
                        }
                        
                        let maxDate = writings[0].date.addingTimeInterval(60 * 60)
                        
                        let minDate = writings[0].date.addingTimeInterval(-60 * 60)
                        
                        var passNumber = 0
                        
                        for writing in writings where writing.date <= maxDate && writing.date >= minDate {
                            passNumber += 1
                        }
                        
                        if passNumber < task.people {
                            completion(Result.success(false))
                            return
                        }
                           
                        self?.changeTaskStatus(task: task)
                        completion(Result.success(true))
                        
                    case .failure(let error):
                        
                        completion(Result.failure(error))
                    }
                }
                
            case .failure(let error):
                
                completion(Result.failure(error))
            }
        }
    }
    
    private func changeTaskStatus(task: TaskData) {
        
        guard let user = UserProvider.shared.userData else { return }
        
        for index in 0..<userTasks.count where userTasks[index].taskID == task.taskID {
            userTasks[index].status = 2
        }
        
        let ref = firestoreReference.usersTasksDocumentRef(userPath: user.uid, taskPath: task.documentID)

        ref.updateData([FirestoreReference.FieldKey.status: 2])
    }
    
    func addMoreTask() {
        
        guard let user = UserProvider.shared.userData else { return }
        
        getTaskTypes { [weak self] (result) in
            
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let taskTypes):
                
                guard let taskType = taskTypes.randomElement() else { return }
                
                let ref = strongSelf.firestoreReference.newUsersTasksDocumentRef(doc: user.uid)
                
                let newTask = TaskData(documentID: ref.documentID, restaurantNumber: user.taskNumber + 3, people: taskType.people, media: taskType.media, composition: taskType.composition, status: 0, taskID: ref.documentID)
                
                strongSelf.firestoreManager.addCustomData(docRef: ref, data: newTask)
                
                strongSelf.userTasks.append(newTask)
                
                NotificationCenter.default.post(name: TTConstant.NotificationName.addRestaurant, object: nil)
                
            case .failure(let error):
                
                print("getTaskTypes error: \(error)")
            }
        }
    }
    
    func updateTask(task: TaskData, completion: @escaping (Result<TaskData, Error>) -> Void) {
        
        guard let user = UserProvider.shared.userData else { return }
        
        getTaskTypes { [weak self] (result) in
            
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let taskTypes):
                
                guard let taskType = taskTypes.randomElement() else { return }
                
                let newRef = strongSelf.firestoreReference.newUsersTasksDocumentRef(doc: user.uid)
                
                let newTask = TaskData(documentID: newRef.documentID, restaurantNumber: task.restaurantNumber, people: taskType.people, media: taskType.media, composition: taskType.composition, status: 0, taskID: newRef.documentID)
                
                strongSelf.firestoreManager.addCustomData(docRef: newRef, data: newTask)
                
                let oldRef = strongSelf.firestoreReference.usersTasksDocumentRef(userPath: user.uid, taskPath: task.documentID)

                oldRef.delete()
                
                for index in 0..<strongSelf.userTasks.count where strongSelf.userTasks[index].taskID == task.taskID {
                    strongSelf.userTasks[index] = newTask
                }
                
                completion(Result.success(newTask))
                
            case .failure(let error):
                print("getTaskTypes error: \(error)")
                completion(Result.failure(error))
            }
        }
    }
    
}
