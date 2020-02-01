//
//  FirestoreManager.swift
//  Tastopia
//
//  Created by FISH on 2020/2/1.
//  Copyright © 2020 FISH. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

class FirestoreManager {
    
    static let shared = FirestoreManager()
    
    let db = Firestore.firestore()
    
    private init() {}
    
    func addData<T: Codable>(collection: String, document: String?, data: T) {
        if let document = document {
            do {
                try db.collection(collection).document(document).setData(from: data)
            } catch {
                print("Firestore setData error: \(error)")
            }
        } else {
            do {
                _ = try db.collection(collection).addDocument(from: data)
            } catch {
                print("Firestore addDocument error: \(error)")
            }
        }
        
    }
}

struct UserData: Codable {
    let uid: String
    let name: String
    let email: String
}
