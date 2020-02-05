//
//  RecordContentViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/5.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class RecordContentViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var agreeRatioView: UIView!
    @IBOutlet weak var agreeRatioViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var recordContentCollectionView: UICollectionView!
    @IBOutlet weak var compositionTextView: UITextView!
    @IBOutlet weak var checkAuthorButton: UIButton!
    @IBOutlet weak var checkResponseButton: UIButton!
    @IBOutlet weak var responseButton: UIButton!
    
    var writing: WritingData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordContentCollectionView.dataSource = self
        recordContentCollectionView.delegate = self

        guard let writing = writing, let uid = UserProvider.shared.uid else { return }
        
        if writing.uid == uid {
            checkAuthorButton.isHidden = true
            responseButton.isHidden = true
        }
        
        titleLabel.text = writing.userName
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = Date(timeIntervalSince1970: TimeInterval(writing.date))
        dateLabel.text = dateFormatter.string(from: date)
        
        compositionTextView.text = writing.composition
    }

}

extension RecordContentViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.width
        return CGSize(width: width, height: width - 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}

extension RecordContentViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let writing = writing else { return 0 }
        return writing.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecordContentCollectionViewCell", for: indexPath) as? RecordContentCollectionViewCell, let writing = writing else { return UICollectionViewCell() }
        
        cell.imageView.loadImage(writing.images[indexPath.item])
        return cell
    }
    
}

extension RecordContentViewController: UICollectionViewDelegate {
    
}
