//
//  TaskRecordViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/4.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class TaskRecordViewController: UIViewController {
    
    @IBOutlet weak var taskRecordCollectionView: UICollectionView!
    
    var restaurant: Restaurant?
    
    let writingProvider = WritingProvider()
    
    var writings = [WritingData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        taskRecordCollectionView.dataSource = self
        taskRecordCollectionView.delegate = self
        
        guard let restaurant = restaurant else { return }
        writingProvider.getWritings(number: restaurant.number) { [weak self] (result) in
            switch result {
            case .success(let writingsData):
                self?.writings = writingsData
                self?.taskRecordCollectionView.reloadData()
            case .failure(let error):
                print("getWritings error: \(error)")
            }
        }
    }
    
}

extension TaskRecordViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.width
        return CGSize(width: width / 2 - 2, height: width / 2 - 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        1
    }
    
}

extension TaskRecordViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return writings.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TaskRecordCollectionViewCell", for: indexPath) as? TaskRecordCollectionViewCell else { return UICollectionViewCell() }
        if !writings[indexPath.item].images.isEmpty {
            cell.imageView.loadImage(writings[indexPath.item].images[0])
        }
        
        return cell
    }
    
}

extension TaskRecordViewController: UICollectionViewDelegate {

}
