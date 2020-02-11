//
//  RecordContentViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/5.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class RecordContentViewController: UIViewController {
    
    @IBOutlet weak var recordTableView: UITableView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var checkResponseBarButtonItem: UIBarButtonItem!
    
    var writing: WritingData?
    
    var responses = [ResponseData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordTableView.dataSource = self
        recordTableView.delegate = self

        guard let writing = writing else { return }
        
        titleLabel.text = writing.userName
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getResponse()
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func checkResponsePressed(_ sender: Any) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "CheckResponseViewController") as? CheckResponseViewController else { return }

        vc.responses = responses
        show(vc, sender: nil)
    }
    
    func agree() {
        guard let uid = UserProvider.shared.uid, var writing = writing else { return }
        let documentID = writing.documentID

        if UserProvider.shared.agreeWritings.contains(documentID) {
            writing.agree -= 1
            UserProvider.shared.agreeWritings.removeAll(where: { $0 == documentID })
            FirestoreManager.shared.deleteArrayData(collection: "Users", document: uid, field: "agreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "agree", increment: -1)
        } else {
            writing.agree += 1
            UserProvider.shared.agreeWritings.append(documentID)
            FirestoreManager.shared.updateArrayData(collection: "Users", document: uid, field: "agreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "agree", increment: 1)
        }

        if UserProvider.shared.disagreeWritings.contains(documentID) {
            writing.disagree -= 1
            UserProvider.shared.disagreeWritings.removeAll(where: { $0 == documentID })
            FirestoreManager.shared.deleteArrayData(collection: "Users", document: uid, field: "disagreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "disagree", increment: -1)
        }

        self.writing = writing
        recordTableView.reloadData()
    }

    func disagree() {
        guard let uid = UserProvider.shared.uid, var writing = writing else { return }
        let documentID = writing.documentID

        if UserProvider.shared.disagreeWritings.contains(documentID) {
            writing.disagree -= 1
            UserProvider.shared.disagreeWritings.removeAll(where: { $0 == documentID })
            FirestoreManager.shared.deleteArrayData(collection: "Users", document: uid, field: "disagreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "disagree", increment: -1)
        } else {
            writing.disagree += 1
            UserProvider.shared.disagreeWritings.append(documentID)
            FirestoreManager.shared.updateArrayData(collection: "Users", document: uid, field: "disagreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "disagree", increment: 1)
        }

        if UserProvider.shared.agreeWritings.contains(documentID) {
            writing.agree -= 1
            UserProvider.shared.agreeWritings.removeAll(where: { $0 == documentID })
            FirestoreManager.shared.deleteArrayData(collection: "Users", document: uid, field: "agreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "agree", increment: -1)
        }

        self.writing = writing
        recordTableView.reloadData()
    }
    
    func countAgreeRatio(agree: Int, disagree: Int) -> Float {
         return Float(agree) / (Float(agree) + Float(disagree))
    }
    
    func getResponse() {
        guard let documentID = writing?.documentID else { return }
//        checkResponseBarButtonItem.isEnabled = false
        ResponseProvider().getResponses(documentID: documentID) { [weak self] (result) in
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let responsesData):
                strongSelf.responses = responsesData
//                strongSelf.checkResponseBarButtonItem.isEnabled = true
            case .failure(let error):
                print("getResponses error: \(error)")
            }
        }
    }
}

extension RecordContentViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let writing = writing, let uid = UserProvider.shared.uid else { return 0 }
        
        if writing.uid == uid {
            return 3
        }
        
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let writing = writing else { return UITableViewCell() }
        
        if indexPath.row == 0 {
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecordContentTopTableViewCell") as? RecordContentTopTableViewCell else { return UITableViewCell() }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let date = writing.date
            cell.dateLabel.text = dateFormatter.string(from: date)
            
            let agreeRatio = countAgreeRatio(agree: writing.agree, disagree: writing.disagree)
            cell.agreeRatioLabel.text = "\(Int(agreeRatio * 100))%"
            
            return cell
            
        } else if indexPath.row == 1 {
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecordContentImageTableViewCell") as? RecordContentImageTableViewCell else { return UITableViewCell() }
            
            cell.writing = writing
            cell.imageCollectionView.reloadData()
            return cell
            
        } else if indexPath.row == 2 {
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecordContentCompositionTableViewCell") as? RecordContentCompositionTableViewCell else { return UITableViewCell() }
            
            cell.compositionLabel.text = writing.composition
            return cell
            
        } else if indexPath.row == 3 {
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecordContentAgreeTableViewCell") as? RecordContentAgreeTableViewCell else { return UITableViewCell() }
            
            if UserProvider.shared.agreeWritings.contains(writing.documentID) {
                cell.agreeButton.isSelected = true
            } else if UserProvider.shared.disagreeWritings.contains(writing.documentID) {
                cell.disagreeButton.isSelected = true
            }
            
            cell.agree = agree
            cell.disagree = disagree
            return cell
        }
        
        return UITableViewCell()
    }
    
}

extension RecordContentViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if let cell = cell as? RecordContentTopTableViewCell, let writing = writing {
                let agreeRatio = CGFloat(countAgreeRatio(agree: writing.agree, disagree: writing.disagree))
                
                let animator = UIViewPropertyAnimator(duration: 1.5, curve: .easeInOut) { [weak self] in
                    cell.agreeRatioWidthConstraint.constant =  cell.agreeRatioBackgroundView.frame.width * agreeRatio
                    self?.view.layoutIfNeeded()
                }
                animator.startAnimation()
                
            }
        }
    }
}
