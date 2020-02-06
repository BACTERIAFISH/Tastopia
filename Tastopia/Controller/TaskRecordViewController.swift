//
//  TaskRecordViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/4.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class TaskRecordViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var personalRecordButton: UIButton!
    @IBOutlet weak var publicRecordButton: UIButton!
    
    @IBOutlet weak var taskRecordPersonalCollectionView: UICollectionView!
    
    @IBOutlet weak var taskRecordPublicCollectionView: UICollectionView!
    
    var restaurant: Restaurant?
    
    let writingProvider = WritingProvider()
    
    var writings = [WritingData]()
    var personalWritings = [WritingData]()
    var publicWritings = [WritingData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        taskRecordPersonalCollectionView.dataSource = self
        taskRecordPersonalCollectionView.delegate = self
        
        taskRecordPublicCollectionView.dataSource = self
        taskRecordPublicCollectionView.delegate = self
        
//        guard let restaurant = restaurant else { return }
//        writingProvider.getWritings(number: restaurant.number) { [weak self] (result) in
//            switch result {
//            case .success(let writingsData):
//                self?.writings = writingsData
//                self?.personalWritings = writingsData.filter({ $0.uid == UserProvider.shared.uid })
//                self?.publicWritings = writingsData.filter({ $0.uid != UserProvider.shared.uid })
//                self?.taskRecordPersonalCollectionView.reloadData()
//                self?.taskRecordPublicCollectionView.reloadData()
//            case .failure(let error):
//                print("getWritings error: \(error)")
//            }
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let restaurant = restaurant else { return }
        writingProvider.getWritings(number: restaurant.number) { [weak self] (result) in
            switch result {
            case .success(let writingsData):
                self?.writings = writingsData
                self?.personalWritings = writingsData.filter({ $0.uid == UserProvider.shared.uid })
                self?.publicWritings = writingsData.filter({ $0.uid != UserProvider.shared.uid })
                self?.taskRecordPersonalCollectionView.reloadData()
                self?.taskRecordPublicCollectionView.reloadData()
            case .failure(let error):
                print("getWritings error: \(error)")
            }
        }
    }
    
    @IBAction func personalRecordButtonPressed(_ sender: UIButton) {
        personalRecordButton.isEnabled = false
        publicRecordButton.isEnabled = true
        taskRecordPersonalCollectionView.isHidden = false
        taskRecordPublicCollectionView.isHidden = true
    }
    
    @IBAction func publicRecordButtonPressed(_ sender: UIButton) {
        personalRecordButton.isEnabled = true
        publicRecordButton.isEnabled = false
        taskRecordPersonalCollectionView.isHidden = true
        taskRecordPublicCollectionView.isHidden = false
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
        if collectionView == taskRecordPersonalCollectionView {
            return personalWritings.count
        } else if collectionView == taskRecordPublicCollectionView {
            return publicWritings.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TaskRecordCollectionViewCell", for: indexPath) as? TaskRecordCollectionViewCell else { return UICollectionViewCell() }
        
        if collectionView == taskRecordPersonalCollectionView {
            if !personalWritings[indexPath.item].images.isEmpty {
                cell.imageView.loadImage(personalWritings[indexPath.item].images[0])
            }
        } else if collectionView == taskRecordPublicCollectionView {
            if !publicWritings[indexPath.item].images.isEmpty {
                cell.imageView.loadImage(publicWritings[indexPath.item].images[0])
            }
        }
        
        return cell
    }
    
}

extension TaskRecordViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "RecordContentViewController") as? RecordContentViewController else { return }
        
        if collectionView == taskRecordPersonalCollectionView {
            vc.writing = personalWritings[indexPath.item]
        } else if collectionView == taskRecordPublicCollectionView {
            vc.writing = publicWritings[indexPath.item]
        }
        
        show(vc, sender: nil)
    }
}
