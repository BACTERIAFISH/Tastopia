//
//  FirestoreManager.swift
//  Tastopia
//
//  Created by FISH on 2020/2/1.
//  Copyright © 2020 FISH. All rights reserved.
//

import Firebase
import FirebaseFirestoreSwift

class FirestoreManager {
    
    let db = Firestore.firestore()
    
    let storage = Storage.storage()
    
    let storageRef: StorageReference!
    
    init() {
        storageRef = storage.reference()
    }
    
    func addData(docRef: DocumentReference, data: [String: Any]) {
        docRef.setData(data, merge: true)
    }
    
    func addCustomData<T: Codable>(docRef: DocumentReference, data: T) {
        do {
            try docRef.setData(from: data, merge: true)
        } catch {
            print("Firestore setData error: \(error)")
        }
    }
    
    func readData(_ ref: DocumentReference, completion: @escaping (Result<DocumentSnapshot?, Error>) -> Void) {

        ref.getDocument { (snapshot, error) in
            
            if let error = error {
                completion(Result.failure(error))
                return
            }
            
            completion(Result.success(snapshot))
        }

    }
    
    func readData(_ ref: CollectionReference, completion: @escaping (Result<QuerySnapshot?, Error>) -> Void) {
        
        ref.getDocuments { (snapshot, error) in
            
            if let error = error {
                completion(Result.failure(error))
                return
            }
            
            completion(Result.success(snapshot))
        }
        
    }
    
    func readData(_ ref: Query, completion: @escaping (Result<QuerySnapshot?, Error>) -> Void) {
        
        ref.getDocuments { (snapshot, error) in
            
            if let error = error {
                completion(Result.failure(error))
                return
            }
            
            completion(Result.success(snapshot))
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
    
    func updateArrayData<T: Codable>(collection: String, document: String, field: String, data: [T], completion: ((Error?) -> Void)? = { _ in }) {
        db.collection(collection).document(document).updateData([
            field: FieldValue.arrayUnion(data)
        ]) { error in
            completion?(error)
        }
    }
    
    func incrementData(collection: String, document: String, field: String, increment: Int64) {
        db.collection(collection).document(document).updateData([
            field: FieldValue.increment(increment)
        ])
    }
    
    func deleteArrayData<T: Codable>(collection: String, document: String, field: String, data: [T]) {
        db.collection(collection).document(document).updateData([
            field: FieldValue.arrayRemove(data)
        ])
    }
    
    func uploadImage(image: UIImage, fileName: String?, completion: @escaping (Result<String, Error>) -> Void) {
        
        let uuid = NSUUID().uuidString
        var path = "images/\(uuid).JPEG"
        if let fileName = fileName {
            path = "users/\(fileName).JPEG"
        }
        
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
    
    func uploadVideo(url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        
        let uuid = NSUUID().uuidString
        let path = "video/\(uuid).MOV"
        
        let videoRef = storageRef.child(path)
        
        do {
            let data = try Data(contentsOf: url)
            let uploadTask = videoRef.putData(data, metadata: nil) { (_, error) in
                if let error = error {
                    completion(Result.failure(error))
                }
                //            guard let metadata = metadata else { return }
                videoRef.downloadURL { (videoURL, error) in
                    if let error = error {
                        completion(Result.failure(error))
                    }
                    
                    guard let downloadURL = videoURL else { return }
                    
                    completion(Result.success(downloadURL.absoluteString))
                }
            }
            uploadTask.resume()
        } catch {
            print(error)
        }
    }
}

struct WritingData: Codable {
    let documentID: String
    let date: Date
    let number: Int
    let uid: String
    let userName: String
    let userImagePath: String
    var composition: String
    var medias: [String]
    var mediaTypes: [String]
    var agree: Int
    var disagree: Int
    var responseNumber: Int
    var taskID: String
}

struct ResponseData: Codable {
    let documentID: String
    let date: Date
    let uid: String
    let userName: String
    let userImagePath: String
    let response: String
}
