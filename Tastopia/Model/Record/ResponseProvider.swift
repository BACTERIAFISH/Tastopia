//
//  ResponseProvider.swift
//  Tastopia
//
//  Created by FISH on 2020/2/6.
//  Copyright © 2020 FISH. All rights reserved.
//

import Foundation

class ResponseProvider {
    
    func getResponses(documentID: String, order: String = "date", descending: Bool = false, completion: @escaping (Result<[ResponseData], Error>) -> Void) {        FirestoreManager().db.collection("Writings").document(documentID).collection("Responses").order(by: order, descending: descending).getDocuments { (query, error) in
            if let error = error {
                completion(Result.failure(error))
                return
            } else {
                var responses = [ResponseData]()
                for doc in query!.documents {
                    let result = Result {
                        try doc.data(as: ResponseData.self)
                    }
                    
                    switch result {
                    case .success(let response):
                        if let response = response {
                            responses.append(response)
                        }
                    case .failure(let error):
                        completion(Result.failure(error))
                    }
                }
                completion(Result.success(responses))
            }
        }
    }
}
