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
}
