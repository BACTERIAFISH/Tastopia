//
//  FirestoreParser.swift
//  Tastopia
//
//  Created by FISH on 2020/3/3.
//  Copyright © 2020 FISH. All rights reserved.
//

import Firebase
import FirebaseFirestoreSwift

class FirestoreParser {
    
    enum FirestoreParserError: Error {
        case noData
        case decodeFail(String)
        case collectionReferenceGetDocumentsError(String)
    }
    
    func parseDocument<T: Codable>(decode snapshot: DocumentSnapshot?, from type: T.Type, completion: @escaping (Result<T, FirestoreParserError>) -> Void) {
        
        let result = Result {
            try snapshot.flatMap {
                try $0.data(as: T.self)
            }
        }
        
        switch result {
        case .success(let data):
            if let data = data {
                completion(Result.success(data))
            } else {
                completion(Result.failure(.noData))
            }
        case .failure(let error):
            completion(Result.failure(.decodeFail(error.localizedDescription)))
        }
    }
    
    func parseDocuments<T: Codable>(decode snapshot: QuerySnapshot?, from type: T.Type, completion: @escaping (Result<[T], FirestoreParserError>) -> Void) {
        var arr: [T] = []
        for doc in snapshot!.documents {
            let result = Result {
                try doc.data(as: type.self)
            }
            
            switch result {
            case .success(let data):
                if let data = data {
                    arr.append(data)
                }
            case .failure(let error):
                print("parseDocuments decode error: \(error)")
                completion(Result.failure(.decodeFail(error.localizedDescription)))
                return
            }
        }
        completion(Result.success(arr))
    }
    
    func parseDocuments<T: Codable>(decode ref: CollectionReference, from type: T.Type, completion: @escaping (Result<[T], FirestoreParserError>) -> Void) {
        
        ref.getDocuments { (query, error) in
            if let error = error {            completion(Result.failure(.collectionReferenceGetDocumentsError(error.localizedDescription)))
                return
            } else {
                var arr: [T] = []
                for doc in query!.documents {
                    let result = Result {
                        try doc.data(as: T.self)
                    }
                    
                    switch result {
                    case .success(let data):
                        if let data = data {
                            arr.append(data)
                        }
                    case .failure(let error):
                        completion(Result.failure(.decodeFail(error.localizedDescription)))
                        return
                    }
                }
                completion(Result.success(arr))
            }
        }
    }
    
}
