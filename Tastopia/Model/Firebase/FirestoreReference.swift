//
//  FirestoreReference.swift
//  Tastopia
//
//  Created by FISH on 2020/3/3.
//  Copyright © 2020 FISH. All rights reserved.
//

import Firebase

class FirestoreReference {
    
    struct Path {
        
        static let users = "Users"
        static let taskTypes = "TaskTypes"
        static let restaurants = "Restaurants"
        static let writings = "Writings"
        static let tasks = "Tasks"
    }
    
    struct FieldKey {
        
        static let name = "name"
        static let number = "number"
        static let taskID = "taskID"
    }
    
    let db = Firestore.firestore()
    
    func usersDocumentRef(doc path: String) -> DocumentReference {
        return db.collection(Path.users).document(path)
    }
    
    func usersTasksCollectionRef(doc path: String) -> CollectionReference {
        return db.collection(Path.users).document(path).collection(Path.tasks)
    }
    
    func newUsersTasksDocumentRef(doc path: String) -> DocumentReference {
        return db.collection(Path.users).document(path).collection(Path.tasks).document()
    }
    
    func taskTypesCollectionRef() -> CollectionReference {
        return db.collection(Path.taskTypes)
    }
    
    func restaurantsQuery(isLessThan number: Int) -> Query {
        return db.collection(Path.restaurants).whereField(FieldKey.number, isLessThan: number)
    }
}
