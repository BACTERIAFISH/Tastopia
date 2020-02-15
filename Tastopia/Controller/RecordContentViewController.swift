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
    
    @IBOutlet weak var responseContainView: UIView!
    
    @IBOutlet weak var responseBackgroundView: UIView!
    
    @IBOutlet weak var responseBackgroundHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var responseTextView: UITextView!
    
    @IBOutlet weak var responseButton: UIButton!
    
    var writing: WritingData?
    
    var responses = [ResponseData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordTableView.dataSource = self
        recordTableView.delegate = self
        
        responseTextView.delegate = self
        
        responseContainView.layer.createTTShadow(color: UIColor.SUMI!.cgColor, offset: CGSize(width: 0, height: -3), radius: 3, opacity: 0.3)
        
        responseButton.layer.cornerRadius = 5
        
        responseBackgroundView.layer.cornerRadius = 5
        responseBackgroundView.layer.createTTBorder()
        
        guard let writing = writing else { return }
        
        titleLabel.text = writing.userName
        
        getResponse()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func responseButtonPressed(_ sender: UIButton) {
        submitResponse()
    }
    
    func agree() {
        guard let user = UserProvider.shared.userData, var writing = writing else { return }
        let documentID = writing.documentID
        
        if user.agreeWritings.contains(documentID) {
            writing.agree -= 1
            UserProvider.shared.userData?.agreeWritings.removeAll(where: { $0 == documentID })
            FirestoreManager.shared.deleteArrayData(collection: "Users", document: user.uid, field: "agreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "agree", increment: -1)
        } else {
            writing.agree += 1
            UserProvider.shared.userData?.agreeWritings.append(documentID)
            FirestoreManager.shared.updateArrayData(collection: "Users", document: user.uid, field: "agreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "agree", increment: 1)
        }
        
        if user.disagreeWritings.contains(documentID) {
            writing.disagree -= 1
            UserProvider.shared.userData?.disagreeWritings.removeAll(where: { $0 == documentID })
            FirestoreManager.shared.deleteArrayData(collection: "Users", document: user.uid, field: "disagreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "disagree", increment: -1)
        }
        
        self.writing = writing
        recordTableView.reloadData()
    }
    
    func disagree() {
        guard let user = UserProvider.shared.userData, var writing = writing else { return }
        let documentID = writing.documentID
        
        if user.disagreeWritings.contains(documentID) {
            writing.disagree -= 1
            UserProvider.shared.userData?.disagreeWritings.removeAll(where: { $0 == documentID })
            FirestoreManager.shared.deleteArrayData(collection: "Users", document: user.uid, field: "disagreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "disagree", increment: -1)
        } else {
            writing.disagree += 1
            UserProvider.shared.userData?.disagreeWritings.append(documentID)
            FirestoreManager.shared.updateArrayData(collection: "Users", document: user.uid, field: "disagreeWritings", data: [documentID])
            FirestoreManager.shared.incrementData(collection: "Writings", document: documentID, field: "disagree", increment: 1)
        }
        
        if user.agreeWritings.contains(documentID) {
            writing.agree -= 1
            UserProvider.shared.userData?.agreeWritings.removeAll(where: { $0 == documentID })
            FirestoreManager.shared.deleteArrayData(collection: "Users", document: user.uid, field: "agreeWritings", data: [documentID])
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
        ResponseProvider().getResponses(documentID: documentID, descending: true) { [weak self] (result) in
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let responsesData):
                strongSelf.responses = responsesData
                var indexPaths = [IndexPath]()
                for i in 0..<responsesData.count {
                    indexPaths.append(IndexPath(item: i, section: 1))
                }
                self?.recordTableView.insertRows(at: indexPaths, with: .automatic)
            case .failure(let error):
                print("getResponses error: \(error)")
            }
        }
    }
    
    func submitResponse() {
        guard let writing = writing, let user = UserProvider.shared.userData, let response = responseTextView.text else { return }
        
        if response == "" {
            responseButton.setTitle("留言", for: .normal)
            view.layoutIfNeeded()
            let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut, animations: { [weak self] in
                self?.responseBackgroundHeightConstraint.constant = 48
                self?.view.layoutIfNeeded()
            })
            animator.startAnimation()
            responseTextView.resignFirstResponder()
            return
        }
        
        let docRef = FirestoreManager.shared.db.collection("Writings").document(writing.documentID).collection("Responses").document()
        
        let data = ResponseData(documentID: docRef.documentID, date: Date(), uid: user.uid, userName: user.name, response: response)
        
        FirestoreManager.shared.addCustomData(docRef: docRef, data: data)
        
        FirestoreManager.shared.incrementData(collection: "Writings", document: writing.documentID, field: "responseNumber", increment: 1)
        
        FirestoreManager.shared.updateArrayData(collection: "Users", document: user.uid, field: "responseWritings", data: [writing.documentID])
        
        responses.append(data)
        recordTableView.insertRows(at: [IndexPath(item: responses.count - 1, section: 1)], with: .automatic)
        
        responseTextView.text = ""
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut, animations: { [weak self] in
            self?.responseBackgroundHeightConstraint.constant = 48
            self?.view.layoutIfNeeded()
        })
        animator.startAnimation()
        
        responseTextView.resignFirstResponder()
        
        recordTableView.scrollToRow(at: IndexPath(item: responses.count - 1, section: 1), at: .bottom, animated: true)
    }
}

extension RecordContentViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if responses.count > 0, section == 1 {
            return "留言"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 4
        } else {
            return responses.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let writing = writing else { return UITableViewCell() }
        
        if indexPath.section == 0 {
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
                
                if UserProvider.shared.userData?.uid == writing.uid {
                    return UITableViewCell()
                    // MARK: for edit composition
                }
                
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecordContentAgreeTableViewCell") as? RecordContentAgreeTableViewCell else { return UITableViewCell() }
                
                cell.documentID = writing.documentID
                cell.agree = agree
                cell.disagree = disagree
                return cell
                
            }
            
            return UITableViewCell()
            
        } else {
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecordContentResponseTableViewCell") as? RecordContentResponseTableViewCell else { return UITableViewCell() }
            
            cell.response = responses[indexPath.row]
            return cell
        }
        
    }
    
}

extension RecordContentViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if let cell = cell as? RecordContentTopTableViewCell, let writing = writing {
                let agreeRatio = CGFloat(countAgreeRatio(agree: writing.agree, disagree: writing.disagree))
                
                DispatchQueue.main.async {
                    let animator = UIViewPropertyAnimator(duration: 1.5, curve: .easeInOut) { [weak self] in
                        cell.agreeRatioWidthConstraint.constant =  cell.agreeRatioBackgroundView.frame.width * agreeRatio
                        self?.view.layoutIfNeeded()
                    }
                    animator.startAnimation()
                }
                
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.contentView.backgroundColor = UIColor.SHIRONERI
        header.textLabel?.font = UIFont(name: "NotoSerifTC-Black", size: 20)
        header.textLabel?.textColor = UIColor.SUMI
//        header.textLabel?.textAlignment = .center
    }
}

extension RecordContentViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if let text = textView.text, text == "" {
            responseButton.setTitle("取消", for: .normal)
            view.layoutIfNeeded()
        }
        
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut, animations: { [weak self] in
            self?.responseBackgroundHeightConstraint.constant = 200
            self?.view.layoutIfNeeded()
        })
        animator.startAnimation()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard let text = textView.text else { return }
        if responseButton.titleLabel?.text == "取消", text != "" {
            responseButton.setTitle("留言", for: .normal)
        }
        if responseButton.titleLabel?.text == "留言", text == "" {
            responseButton.setTitle("取消", for: .normal)
        }
        
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        submitResponse()
    }
}
