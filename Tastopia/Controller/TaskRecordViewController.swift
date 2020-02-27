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
import collection_view_layouts

enum SortMethod: String {
    case agree = "中肯"
    case dateDescending = "最新"
    case dateAscending = "最舊"
    case comment = "中肯或留言"
    case response = "留言"
}

class TaskRecordViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var indicatorView: UIView!
    @IBOutlet weak var indicatorViewLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var personalRecordButton: UIButton!
    @IBOutlet weak var publicRecordButton: UIButton!
    
    @IBOutlet weak var taskRecordPersonalCollectionView: UICollectionView!
    
    @IBOutlet weak var personalCollectionViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var taskRecordPublicCollectionView: UICollectionView!
    
    @IBOutlet weak var emptyView: UIView!
    
    var restaurant: Restaurant?
    
    let writingProvider = WritingProvider()
    
    var personalWritingsOrigin = [WritingData]()
    var publicWritingsOrigin = [WritingData]()
    var personalWritings = [WritingData]()
    var publicWritings = [WritingData]()
    
    var sortMethod: SortMethod = .dateDescending
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        taskRecordPersonalCollectionView.dataSource = self
        taskRecordPersonalCollectionView.delegate = self
        
        taskRecordPublicCollectionView.dataSource = self
        taskRecordPublicCollectionView.delegate = self
        
        // MARK: collection-view-layouts
        let layout = InstagramLayout()
        layout.delegate = self
        layout.cellsPadding = ItemsPadding(horizontal: 1, vertical: 1)
        taskRecordPublicCollectionView.collectionViewLayout = layout
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let restaurant = restaurant, let user = UserProvider.shared.userData else { return }
        writingProvider.getWritings(number: restaurant.number) { [weak self] (result) in
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let writingsData):
                strongSelf.personalWritingsOrigin = writingsData.filter({ $0.uid == user.uid })
                strongSelf.publicWritingsOrigin = writingsData.filter({ $0.uid != user.uid })
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
        let ac = UIAlertController(title: "篩選排序", message: nil, preferredStyle: .actionSheet)
        let action1 = UIAlertAction(title: "中肯", style: .default, handler: setSortMethod(action:))
        ac.addAction(action1)
        let action2 = UIAlertAction(title: "最新", style: .default, handler: setSortMethod(action:))
        ac.addAction(action2)
        let action3 = UIAlertAction(title: "最舊", style: .default, handler: setSortMethod(action:))
        ac.addAction(action3)
        var action4 = UIAlertAction(title: "中肯或留言", style: .default, handler: setSortMethod(action:))
        if personalCollectionViewTrailingConstraint.constant == 0 {
            action4 = UIAlertAction(title: "留言", style: .default, handler: setSortMethod(action:))
        }
        ac.addAction(action4)
        let actionCancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        ac.addAction(actionCancel)
        
        //        ac.view.tintColor = UIColor.AKABENI
        present(ac, animated: true)
    }
    
    @IBAction func personalRecordButtonPressed(_ sender: UIButton) {
        emptyView.isHidden = true
        personalRecordButton.isEnabled = false
        publicRecordButton.isEnabled = true
        
        personalRecordButton.setTitleColor(UIColor.AKABENI, for: .normal)
        publicRecordButton.setTitleColor(UIColor.SUMI, for: .normal)
        
        indicatorViewLeadingConstraint.isActive = false
        
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.indicatorViewLeadingConstraint = strongSelf.indicatorView.centerXAnchor.constraint(equalTo: strongSelf.personalRecordButton.centerXAnchor)
            strongSelf.indicatorViewLeadingConstraint.isActive = true
            //            self?.indicatorViewLeadingConstraint.constant = 20
            strongSelf.personalCollectionViewTrailingConstraint.constant = 0
            strongSelf.view.layoutIfNeeded()
        }
        animator.addCompletion { [weak self] _ in
            self?.toggleEmptyView()
        }
        animator.startAnimation()
    }
    
    @IBAction func publicRecordButtonPressed(_ sender: UIButton) {
        emptyView.isHidden = true
        personalRecordButton.isEnabled = true
        publicRecordButton.isEnabled = false
        
        personalRecordButton.setTitleColor(UIColor.SUMI, for: .normal)
        publicRecordButton.setTitleColor(UIColor.AKABENI, for: .normal)
        
        indicatorViewLeadingConstraint.isActive = false
        
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.indicatorViewLeadingConstraint = strongSelf.indicatorView.centerXAnchor.constraint(equalTo: strongSelf.publicRecordButton.centerXAnchor)
            strongSelf.indicatorViewLeadingConstraint.isActive = true
            //            self?.indicatorViewLeadingConstraint.constant = sender.frame.width + 20
            self?.personalCollectionViewTrailingConstraint.constant = sender.frame.width * 2
            self?.view.layoutIfNeeded()
        }
        animator.addCompletion { [weak self] _ in
            self?.toggleEmptyView()
        }
        animator.startAnimation()
    }
    
    func setSortMethod(action: UIAlertAction) {
        guard let title = action.title, let method = SortMethod(rawValue: title) else { return }
        
        sortMethod = method
        sortRecord()
    }
    
    func sortRecord() {
        emptyView.isHidden = true
        
        guard let user = UserProvider.shared.userData else { return }
        
        personalWritings = personalWritingsOrigin
        publicWritings = publicWritingsOrigin.filter({ !user.blackList.contains($0.uid) })
        
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
            let writings = user.agreeWritings + user.disagreeWritings + user.responseWritings
            publicWritings = publicWritings.filter({ writings.contains($0.documentID) })
            personalWritings = personalWritings.filter({ $0.responseNumber > 0 })
        }
        taskRecordPersonalCollectionView.reloadData()
        taskRecordPublicCollectionView.reloadData()
        toggleEmptyView()
    }
    
    func countAgreeRatio(agree: Int, disagree: Int) -> Float {
        return Float(agree) / (Float(agree) + Float(disagree))
    }
    
    func toggleEmptyView() {
        if personalCollectionViewTrailingConstraint.constant == 0 {
            if personalWritings.isEmpty {
                emptyView.isHidden = false
            }
        } else {
            if publicWritings.isEmpty {
                emptyView.isHidden = false
            }
        }
    }
}

extension TaskRecordViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.width
        return CGSize(width: width / 2 - 7.5, height: width / 2  - 7.5)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 1, left: 5, bottom: 5, right: 5)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        5
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
        
        cell.imageView.image = UIImage.asset(.Image_Tastopia_01_square)
        cell.playerLooper = nil
        cell.movieView.isHidden = true
        
        var writing: WritingData?
        if collectionView == taskRecordPersonalCollectionView {
            writing = personalWritings[indexPath.item]
        } else if collectionView == taskRecordPublicCollectionView {
            writing = publicWritings[indexPath.item]
        }
        if let writing = writing {
            if !writing.medias.isEmpty {
                if writing.mediaTypes[0] == kUTTypeImage as String {
                    cell.imageView.loadImage(writing.medias[0], placeHolder: UIImage.asset(.Image_Tastopia_01_square))
                } else if writing.mediaTypes[0] == kUTTypeMovie as String {
                    cell.urlString = writing.medias[0]
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
        
        vc.titleLabel.text = restaurant?.name
        
        if collectionView == taskRecordPersonalCollectionView {
            vc.writing = personalWritings[indexPath.item]
        } else if collectionView == taskRecordPublicCollectionView {
            vc.writing = publicWritings[indexPath.item]
        }
        
        show(vc, sender: nil)
    }
    
}

// MARK: collection-view-layouts
extension TaskRecordViewController: LayoutDelegate {
    
    func cellSize(indexPath: IndexPath) -> CGSize {
        return CGSize(width: 10, height: 10)
    }
    
}
