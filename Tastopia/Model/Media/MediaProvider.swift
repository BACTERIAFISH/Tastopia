//
//  MediaProvider.swift
//  Tastopia
//
//  Created by FISH on 2020/3/28.
//  Copyright © 2020 FISH. All rights reserved.
//

import Foundation
import UIKit
import Photos

class MediaProvider {
    
    var images: [UIImage] = []
    
    var fetchStartIndex = 0
    
    var fetchRange: Int = {

        let height = UIScreen.main.bounds.height
        let width = UIScreen.main.bounds.width
        return (Int(height / (width / 3)) + 1) * 3 * 5
    }()
    
    func grabPhotos(completion: @escaping (Result<[UIImage], Error>) -> Void) {
        
        images = []
        
        DispatchQueue.global().async { [weak self] in
            
            guard let strongSelf = self else { return }
            
            let imgManager = PHImageManager.default()
            
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .highQualityFormat
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            var fetchEndIndex = strongSelf.fetchStartIndex + strongSelf.fetchRange
            
            if fetchEndIndex > fetchResult.count {
                fetchEndIndex = fetchResult.count
            }
            
            if fetchResult.count > 0, strongSelf.fetchStartIndex != fetchEndIndex {
                
                for index in strongSelf.fetchStartIndex..<fetchEndIndex {
                    
                    strongSelf.images.append(UIImage.asset(.Image_Tastopia_01_square)!)
                    
                    imgManager.requestImage(for: fetchResult.object(at: index), targetSize: CGSize(width: 400, height: 400), contentMode: .aspectFill, options: requestOptions) { (image, _) in
                        
                        if let image = image {
                            strongSelf.images[index - strongSelf.fetchStartIndex] = image
                        } else {
                            print("grabPhotos: no image")
                        }
                    }
                }
                
                strongSelf.fetchStartIndex = fetchEndIndex
                
                completion(Result.success(strongSelf.images))
                
            } else {
                print("grabPhotos: no photos")
                
            }
        }
        
    }
}
