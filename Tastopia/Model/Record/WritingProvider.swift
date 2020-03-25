//
//  WritingProvider.swift
//  Tastopia
//
//  Created by FISH on 2020/2/4.
//  Copyright © 2020 FISH. All rights reserved.
//

import Foundation
//import AVFoundation
import MobileCoreServices

class WritingProvider {
    
    let firestoreManager = FirestoreManager()
    
    func getWritings(number: Int, order: String = "date", completion: @escaping (Result<[WritingData], Error>) -> Void) {
        
        firestoreManager.db.collection("Writings").whereField("number", isEqualTo: number).order(by: "date", descending: true).getDocuments { (query, error) in
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
    
    func uploadWriting(selectedMedias: [TTMediaData], user: UserData, task: TaskData, composition: String, completion: @escaping () -> Void) {
        
        var medias = selectedMedias
        
        let group = DispatchGroup()
        for (index, media) in medias.enumerated() {
            
            group.enter()
            if media.mediaType == kUTTypeImage as String, let image = media.image {
                
                firestoreManager.uploadImage(image: image, fileName: nil) { (result) in
                    switch result {
                    case .success(let urlString):
                        
                        medias[index].urlString = urlString
                        group.leave()
                        
                    case .failure(let error):
                        
                        print("submitTask error: \(error)")
                        group.leave()
                    }
                }
                
            } else if media.mediaType == kUTTypeMovie as String, let url = media.url {
                
                firestoreManager.uploadVideo(url: url) { (result) in
                    
                    switch result {
                    case .success(let urlString):
                        
                        medias[index].urlString = urlString
                        group.leave()
                        
                    case .failure(let error):
                        
                        print("submitTask error: \(error)")
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            
            var urlStrings = [String]()
            var mediaTypes = [String]()
            
            for media in medias {
                urlStrings.append(media.urlString)
                mediaTypes.append(media.mediaType)
            }
            
            let docRef = FirestoreReference().newWritingRef()
            
            let data = WritingData(documentID: docRef.documentID, date: Date(), number: task.restaurantNumber, uid: user.uid, userName: user.name, userImagePath: user.imagePath, composition: composition, medias: urlStrings, mediaTypes: mediaTypes, agree: 1, disagree: 0, responseNumber: 0, taskID: task.taskID)
            
            self?.firestoreManager.addCustomData(docRef: docRef, data: data)
            
            completion()
        }
    }
    
}
