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
    }
    
    func usersDocumentRef(doc path: String) -> DocumentReference {
        return Firestore.firestore().collection(FirestorePath.users).document(path)
    }
    
}
