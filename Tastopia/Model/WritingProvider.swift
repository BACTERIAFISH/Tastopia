//
//  WritingProvider.swift
//  Tastopia
//
//  Created by FISH on 2020/2/4.
//  Copyright © 2020 FISH. All rights reserved.
//

import Foundation

class WritingProvider {
    
    func getWritings(number: Int, order: String = "date", completion: @escaping (Result<[WritingData], Error>) -> Void) {
        FirestoreManager.shared.db.collection("Writings").whereField("number", isEqualTo: number).order(by: "date", descending: true).getDocuments { (query, error) in
            if let error = error {
                completion(Result.failure(error))
                return
            } else {
                var writings = [WritingData]()
                for doc in query!.documents {
                    let result = Result {
                        try doc.data(as: WritingData.self)
                    }
                    
                    switch result {
                    case .success(let writing):
                        if let writing = writing {
                            writings.append(writing)
                        }
                    case .failure(let error):
                        completion(Result.failure(error))
                    }
                }
                completion(Result.success(writings))
            }
            
        }
    }
    
    func checkTaskWritings(task: TaskData, completion: @escaping (Result<Bool, Error>) -> Void) {
        FirestoreManager.shared.db.collection("Writings").whereField("taskID", isEqualTo: task.taskID).getDocuments { (query, error) in
            if let error = error {
                completion(Result.failure(error))
                return
            } else {
                if query!.documents.count < task.people {
                    completion(Result.success(false))
                } else {
                    var writings = [WritingData]()
                    for doc in query!.documents {
                        let result = Result {
                            try doc.data(as: WritingData.self)
                        }
                        
                        switch result {
                        case .success(let writing):
                            if let writing = writing {
                                writings.append(writing)
                            }
                        case .failure(let error):
                            completion(Result.failure(error))
                            return
                        }
                    }
                    writings = writings.filter({ $0.number == task.restaurantNumber })
                    if writings.count < task.people {
                        completion(Result.success(false))
                        return
                    }
                    let maxDate = writings[0].date.addingTimeInterval(60 * 60)
                    let minDate = writings[0].date.addingTimeInterval(-60 * 60)
                    var passNumber = 0
                    for writing in writings {
                        if writing.date <= maxDate, writing.date >= minDate {
                            passNumber += 1
                        }
                    }
                    if passNumber < task.people {
                        completion(Result.success(false))
                    } else {
                        completion(Result.success(true))
                    }
                }
            }
            
        }
    }
    
}
