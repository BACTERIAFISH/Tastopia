//
//  FirestoreReference.swift
//  Tastopia
//
//  Created by FISH on 2020/3/3.
//  Copyright © 2020 FISH. All rights reserved.
//

import Firebase

class FirestoreReference {
    
    struct FirestorePath {
        static let users = "Users"
        static let taskTypes = "TaskTypes"
        static let restaurants = "Restaurants"
        static let writings = "Writings"
        static let tasks = "Tasks"
    }
    
    let db = Firestore.firestore()
    
    func usersDocumentRef(doc path: String) -> DocumentReference {
        return db.collection(FirestorePath.users).document(path)
    }
    
    func usersTasksCollectionRef(doc path: String) -> CollectionReference {
        return db.collection(FirestorePath.users).document(path).collection(FirestorePath.tasks)
    }
    
    func newUsersTasksDocumentRef(doc path: String) -> DocumentReference {
        return db.collection(FirestorePath.users).document(path).collection(FirestorePath.tasks).document()
    }
    
    func taskTypesCollectionRef() -> CollectionReference {
        return db.collection(FirestorePath.taskTypes)
    }
    
}
