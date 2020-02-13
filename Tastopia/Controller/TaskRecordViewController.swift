//
//  TaskRecordViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/4.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation

enum SortMethod: String {
    case agree = "中肯值"
    case dateDescending = "日期 新 -> 舊"
    case dateAscending = "日期 舊 -> 新"
    case comment = "點過中肯或留言"
    case response = "有留言"
}

class TaskRecordViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var indicatorViewLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var personalRecordButton: UIButton!
    @IBOutlet weak var publicRecordButton: UIButton!
    
    @IBOutlet weak var taskRecordPersonalCollectionView: UICollectionView!
    
    @IBOutlet weak var personalCollectionViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var taskRecordPublicCollectionView: UICollectionView!
    
    var restaurant: Restaurant?
    
    let writingProvider = WritingProvider()
    
    var personalWritingsOrigin = [WritingData]()
    var publicWritingsOrigin = [WritingData]()
    var personalWritings = [WritingData]()
    var publicWritings = [WritingData]()
    
    var sortMethod: SortMethod = .dateDescending
    
    var playerLoopers = [AVPlayerLooper]()
    
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
                strongSelf.personalWritingsOrigin = writingsData.filter({ $0.uid == UserProvider.shared.uid })
                strongSelf.publicWritingsOrigin = writingsData.filter({ $0.uid != UserProvider.shared.uid })
                strongSelf.sortRecord()
            case .failure(let error):
                print("getWritings error: \(error)")
            }
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
        if personalCollectionViewTrailingConstraint.constant == 0 {
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
        
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) { [weak self] in
            self?.indicatorViewLeadingConstraint.constant = 0
            self?.personalCollectionViewTrailingConstraint.constant = 0
            self?.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }
    
    @IBAction func publicRecordButtonPressed(_ sender: UIButton) {
        personalRecordButton.isEnabled = true
        publicRecordButton.isEnabled = false
        
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) { [weak self] in
            self?.indicatorViewLeadingConstraint.constant = sender.frame.width
            self?.personalCollectionViewTrailingConstraint.constant = sender.frame.width * 2
            self?.view.layoutIfNeeded()
        }
        animator.startAnimation()
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
        
        var writing: WritingData?
        if collectionView == taskRecordPersonalCollectionView {
            writing = personalWritings[indexPath.item]
        } else if collectionView == taskRecordPublicCollectionView {
            writing = publicWritings[indexPath.item]
        }
        if let writing = writing {
            if writing.medias.isEmpty {
                cell.imageView.image = UIImage.asset(.Icon_512px_Ramen)
            } else {
                if writing.mediaTypes[0] == kUTTypeImage as String {
                    cell.imageView.loadImage(writing.medias[0], placeHolder: UIImage.asset(.Icon_512px_Ramen))
                } else if writing.mediaTypes[0] == kUTTypeMovie as String {
                    if let url = URL(string: writing.medias[0]) {
                        let player = AVQueuePlayer()
                        let playerItem = AVPlayerItem(url: url)
                        let playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
                        playerLoopers.append(playerLooper)
                        let playerLayer = AVPlayerLayer(player: player)
                        playerLayer.videoGravity = .resizeAspectFill
                        playerLayer.frame = cell.movieView.bounds
                        cell.movieView.layer.addSublayer(playerLayer)
                        player.play()
                    }
                }
                
                if writing.responseNumber > 0 {
                    cell.commentImageView.isHidden = false
                } else {
                    cell.commentImageView.isHidden = true
                }
                
                switch sortMethod {
                case .agree:
                    let ratio = Int(countAgreeRatio(agree: writing.agree, disagree: writing.disagree) * 100)
                    cell.sortLabel.text = "\(ratio)%"
                case .dateAscending, .dateDescending, .comment, .response:
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    cell.sortLabel.text = dateFormatter.string(from: writing.date)
                }
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
