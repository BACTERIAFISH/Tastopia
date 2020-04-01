//
//  PeopleNumberDetecter.swift
//  Tastopia
//
//  Created by FISH on 2020/3/30.
//  Copyright © 2020 FISH. All rights reserved.
//

import Foundation
import UIKit
import Vision

class PeopleNumberCalculator {
    
    private func detectFace(image: UIImage, completion: @escaping (Result<Int, Error>) -> Void) {
        
        let request = VNDetectFaceRectanglesRequest { (req, err) in
            if let err = err {
                completion(Result.failure(err))
                return
            }
            
            guard let results = req.results else {
                return
            }
            
            completion(Result.success(results.count))
        }
        
        guard let cgImage = image.cgImage else { return }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global().async {
            do {
                try handler.perform([request])
            } catch {
                completion(Result.failure(error))
            }
        }
    }
    
    func checkPeopleNumber(images: [UIImage], needPeopleNumber: Int, completion: @escaping (Bool) -> Void) {
        
        var isPass = false
        
        let group = DispatchGroup()
        
        for image in images {
            group.enter()
            detectFace(image: image) { (result) in
                switch result {
                case .success(let number):
                    if number >= needPeopleNumber {
                        isPass = true
                    }
                    group.leave()
                case .failure(let error):
                    print(error.localizedDescription)
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            
            DispatchQueue.main.async {
                completion(isPass)
            }
        }
    }
    
}
