//
//  FirestoreManager.swift
//  Tastopia
//
//  Created by FISH on 2020/2/1.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import FirebaseFirestoreSwift

class FirestoreManager {
    
    static let shared = FirestoreManager()
    
    let db = Firestore.firestore()
    
    let storage = Storage.storage()
    
    let storageRef: StorageReference!
    
    private init() {
        storageRef = storage.reference()
    }
    
    func createDocumentID(collection: String) -> String {
        let ref = db.collection(collection).document()
        return ref.documentID
    }
    
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
    
    func updateArrayData<T: Codable>(collection: String, document: String, field: String, data: [T]) {
        db.collection(collection).document(document).updateData([
            field: FieldValue.arrayUnion(data)
        ])
    }
    
    func incrementArrayData(collection: String, document: String, field: String, increment: Int64) {
        db.collection(collection).document(document).updateData([
            field: FieldValue.increment(increment)
        ])
    }
    
    func deleteArrayData<T: Codable>(collection: String, document: String, field: String, data: [T]) {
        db.collection(collection).document(document).updateData([
            field: FieldValue.arrayRemove(data)
        ])
    }
    
    func uploadImage(image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        
        let uuid = NSUUID().uuidString
        let path = "images/\(uuid).JPEG"
        
        let imageRef = storageRef.child(path)
        
        guard let data = image.jpegData(compressionQuality: 0.5) else { return }
        
        let uploadTask = imageRef.putData(data, metadata: nil) { (_, error) in
            if let error = error {
                completion(Result.failure(error))
            }
//            guard let metadata = metadata else { return }
            imageRef.downloadURL { (url, error) in
                if let error = error {
                    completion(Result.failure(error))
                }
                
                guard let downloadURL = url else { return }
                
                completion(Result.success(downloadURL.absoluteString))
            }
        }
        
        uploadTask.resume()
    }
}

struct UserData: Codable {
    let uid: String
    let name: String
    let email: String
}

struct WritingData: Codable {
    let documentID: String
    let date: Date
    let number: Int
    let uid: String
    let userName: String
    var composition: String
    var images: [String]
    var agree: Int
    var disagree: Int
}

struct ResponseData: Codable {
    let documentID: String
    let date: Date
    let linkedDocumentID: String
    let uid: String
    let userName: String
    let response: String
}
