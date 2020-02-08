//
//  TaskRecordViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/4.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

enum SortMethod: String {
    case agree = "中肯值"
    case dateDescending = "日期 新 -> 舊"
    case dateAscending = "日期 舊 -> 新"
    case comment = "點過中肯或留言"
    case response = "有留言"
}

class TaskRecordViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var personalRecordButton: UIButton!
    @IBOutlet weak var publicRecordButton: UIButton!
    
    @IBOutlet weak var taskRecordPersonalCollectionView: UICollectionView!
    
    @IBOutlet weak var taskRecordPublicCollectionView: UICollectionView!
    
    var restaurant: Restaurant?
    
    let writingProvider = WritingProvider()
    
//    var writings = [WritingData]()
    var personalWritings = [WritingData]()
    var publicWritings = [WritingData]()
    var personalWritingsOrigin = [WritingData]()
    var publicWritingsOrigin = [WritingData]()
    
    var sortMethod: SortMethod = .dateDescending
    
    override func viewDidLoad() {
        super.viewDidLoad()

        taskRecordPersonalCollectionView.dataSource = self
        taskRecordPersonalCollectionView.delegate = self
        
        taskRecordPublicCollectionView.dataSource = self
        taskRecordPublicCollectionView.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let restaurant = restaurant else { return }
        writingProvider.getWritings(number: restaurant.number) { [weak self] (result) in
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let writingsData):
//                self?.writings = writingsData
//                strongSelf.personalWritings = writingsData.filter({ $0.uid == UserProvider.shared.uid })
                strongSelf.personalWritingsOrigin = writingsData.filter({ $0.uid == UserProvider.shared.uid })
//                strongSelf.publicWritings = writingsData.filter({ $0.uid != UserProvider.shared.uid })
                strongSelf.publicWritingsOrigin = writingsData.filter({ $0.uid != UserProvider.shared.uid })
//                self?.taskRecordPersonalCollectionView.reloadData()
//                self?.taskRecordPublicCollectionView.reloadData()
                strongSelf.sortRecord()
            case .failure(let error):
                print("getWritings error: \(error)")
            }
        }
    }
    
    @IBAction func sortFilterPressed(_ sender: Any) {
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let action1 = UIAlertAction(title: "中肯值", style: .default, handler: setSortMethod(action:))
              ac.addAction(action1)
        let action2 = UIAlertAction(title: "日期 新 -> 舊", style: .default, handler: setSortMethod(action:))
        ac.addAction(action2)
        let action3 = UIAlertAction(title: "日期 舊 -> 新", style: .default, handler: setSortMethod(action:))
        ac.addAction(action3)
        var action4 = UIAlertAction(title: "點過中肯或留言", style: .default, handler: setSortMethod(action:))
        if taskRecordPublicCollectionView.isHidden {
            action4 = UIAlertAction(title: "有留言", style: .default, handler: setSortMethod(action:))
        }
        ac.addAction(action4)
        let actionCancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        ac.addAction(actionCancel)
        present(ac, animated: true)
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
    
    func setSortMethod(action: UIAlertAction) {
        guard let title = action.title, let method = SortMethod(rawValue: title) else { return }
        sortMethod = method
        
        sortRecord()
    }
    
    func sortRecord() {
        personalWritings = personalWritingsOrigin
        publicWritings = publicWritingsOrigin
        
        switch sortMethod {
        case .agree:
            personalWritings.sort(by: { countAgreeRatio(agree: $0.agree, disagree: $0.disagree) > countAgreeRatio(agree: $1.agree, disagree: $1.disagree) })
            publicWritings.sort(by: { countAgreeRatio(agree: $0.agree, disagree: $0.disagree) > countAgreeRatio(agree: $1.agree, disagree: $1.disagree) })
        case .dateDescending:
            personalWritings.sort(by: { $0.date > $1.date })
            publicWritings.sort(by: { $0.date > $1.date })
        case .dateAscending:
            personalWritings.sort(by: { $0.date < $1.date })
            publicWritings.sort(by: { $0.date < $1.date })
        case .comment, .response:
            let writings = UserProvider.shared.agreeWritings + UserProvider.shared.disagreeWritings + UserProvider.shared.responseWritings
            publicWritings = publicWritings.filter({ writings.contains($0.documentID) })
            personalWritings = personalWritings.filter({ $0.responseNumber > 0 })
        }
        taskRecordPersonalCollectionView.reloadData()
        taskRecordPublicCollectionView.reloadData()
    }
    
    func countAgreeRatio(agree: Int, disagree: Int) -> Float {
         return Float(agree) / (Float(agree) + Float(disagree))
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
            if personalWritings[indexPath.item].images.isEmpty {
                cell.imageView.image = nil
            } else {                cell.imageView.loadImage(personalWritings[indexPath.item].images[0])
            }
        } else if collectionView == taskRecordPublicCollectionView {
            if publicWritings[indexPath.item].images.isEmpty {
                cell.imageView.image = nil
            } else {                cell.imageView.loadImage(publicWritings[indexPath.item].images[0])
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
