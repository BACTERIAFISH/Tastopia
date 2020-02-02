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
    
    func addData(collection: String, document: String?, data: [String: Any]) {
        if let document = document {
            db.collection(collection).document(document).setData(data, merge: true)
        } else {
            db.collection(collection).addDocument(data: data)
        }
    }
    
    func addCustomData<T: Codable>(collection: String, document: String?, data: T) {
        if let document = document {
            do {
                try db.collection(collection).document(document).setData(from: data, merge: true)
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
    
    func checkData(collection: String, document: String, completion: @escaping (Bool) -> Void) {
        let docRef = db.collection(collection).document(document)
        docRef.getDocument { (doc, error) in
            if let error = error {
                print("Firestore getDocument error: \(error)")
                return
            }
            if let doc = doc, doc.exists {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func readData(collection: String, document: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let docRef = db.collection(collection).document(document)
        docRef.getDocument { (doc, error) in
            if let error = error {
                completion(Result.failure(error))
                return
            }
            if let doc = doc, doc.exists, let data = doc.data() {
                completion(Result.success(data))
            } else {
                print("Document does not exist.")
            }
        }
    }
    
    func readCustomData<T: Codable>(collection: String, document: String, dataType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        
        let docRef = db.collection(collection).document(document)
        
        docRef.getDocument { (doc, error) in
            if let error = error {
                completion(Result.failure(error))
                return
            }
            let result = Result {
                try doc.flatMap {
                    try $0.data(as: T.self)
                }
            }
            switch result {
            case .success(let data):
                if let data = data {
                    completion(Result.success(data))
                } else {
                    print("Document does not exist.")
                }
            case .failure(let error):
                completion(Result.failure(error))
            }
        }
    }
}

struct UserData: Codable {
    let uid: String
    let name: String
    let email: String
}
