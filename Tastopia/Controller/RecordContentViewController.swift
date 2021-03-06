//
//  RecordContentViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/5.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class RecordContentViewController: UIViewController {
    
    @IBOutlet weak var userButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var recordTableView: UITableView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var responseContainView: UIView!
    
    @IBOutlet weak var responseBackgroundView: UIView!
    
    @IBOutlet weak var responseBackgroundHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var responseTextView: UITextView!
    
    @IBOutlet weak var responseButton: UIButton!
    
    var writing: WritingData?
    
    var responses = [ResponseData]()
    
    var cells: [TTCellModel] = [
        TTRecordContentTopCellModel(),
        TTRecordContentImageCellModel(),
        TTRecordContentCompositionCellModel(),
        TTRecordContentAgreeCellModel()
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordTableView.dataSource = self
        recordTableView.delegate = self
        
        responseTextView.delegate = self
        
        setBeginLayout()
        
        getResponse()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    @IBAction func userButtonPressed(_ sender: Any) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        //        let seeAction = UIAlertAction(title: "查看作者", style: .default) { (action) in
        //
        //        }
        let reportAction = UIAlertAction(title: "檢舉文章", style: .default) { _ in
            TTSwiftMessages().question(title: "檢舉文章", body: "確定要檢舉這篇文章？", leftButtonTitle: "取消", rightButtonTitle: "確定", rightHandler: {
                
                TTSwiftMessages().show(color: UIColor.SUMI!, icon: UIImage.asset(.Icon_32px_Success_White)!, title: "檢舉已收到", body: "將會盡快處理您的檢舉\n如果不想看到文章\n請選擇封鎖作者", duration: 3)
            })
        }
        let blockAction = UIAlertAction(title: "封鎖作者", style: .default) { [weak self] _ in
            TTSwiftMessages().question(title: "封鎖作者", body: "不再顯示該作者的文章和留言\n確定要封鎖作者？", leftButtonTitle: "取消", rightButtonTitle: "確定", rightHandler: {
                self?.blockAuthor()
            })
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(reportAction)
        alertController.addAction(blockAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    @IBAction func responseButtonPressed(_ sender: UIButton) {
        submitResponse()
    }
    
    func setBeginLayout() {
        
        navigationController?.navigationBar.tintColor = UIColor.AKABENI!
        navigationController?.navigationBar.backIndicatorImage = UIImage.asset(.Icon_24px_Left_Arrow)
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage.asset(.Icon_24px_Left_Arrow)
        
        responseContainView.layer.cornerRadius = 16
        responseContainView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        responseContainView.layer.createTTShadow(color: UIColor.SHIRONEZUMI!.cgColor, offset: CGSize(width: 0, height: -2), radius: 3, opacity: 1)
        
        responseButton.layer.cornerRadius = 16
        
        responseBackgroundView.layer.cornerRadius = 16
        responseBackgroundView.layer.createTTBorder()
        
        guard let writing = writing, let user = UserProvider.shared.userData else { return }
        
        if user.uid == writing.uid {
            userButtonItem.isEnabled = false
        }
        
    }
    
    func agree() {
        guard let user = UserProvider.shared.userData, var writing = writing else { return }
        let documentID = writing.documentID
        
        if user.agreeWritings.contains(documentID) {
            writing.agree -= 1
            UserProvider.shared.userData?.agreeWritings.removeAll(where: { $0 == documentID })
            FirestoreManager().deleteArrayData(collection: "Users", document: user.uid, field: "agreeWritings", data: [documentID])
            FirestoreManager().incrementData(collection: "Writings", document: documentID, field: "agree", increment: -1)
        } else {
            writing.agree += 1
            UserProvider.shared.userData?.agreeWritings.append(documentID)
            FirestoreManager().updateArrayData(collection: "Users", document: user.uid, field: "agreeWritings", data: [documentID])
            FirestoreManager().incrementData(collection: "Writings", document: documentID, field: "agree", increment: 1)
        }
        
        if user.disagreeWritings.contains(documentID) {
            writing.disagree -= 1
            UserProvider.shared.userData?.disagreeWritings.removeAll(where: { $0 == documentID })
            FirestoreManager().deleteArrayData(collection: "Users", document: user.uid, field: "disagreeWritings", data: [documentID])
            FirestoreManager().incrementData(collection: "Writings", document: documentID, field: "disagree", increment: -1)
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
            FirestoreManager().deleteArrayData(collection: "Users", document: user.uid, field: "disagreeWritings", data: [documentID])
            FirestoreManager().incrementData(collection: "Writings", document: documentID, field: "disagree", increment: -1)
        } else {
            writing.disagree += 1
            UserProvider.shared.userData?.disagreeWritings.append(documentID)
            FirestoreManager().updateArrayData(collection: "Users", document: user.uid, field: "disagreeWritings", data: [documentID])
            FirestoreManager().incrementData(collection: "Writings", document: documentID, field: "disagree", increment: 1)
        }
        
        if user.agreeWritings.contains(documentID) {
            writing.agree -= 1
            UserProvider.shared.userData?.agreeWritings.removeAll(where: { $0 == documentID })
            FirestoreManager().deleteArrayData(collection: "Users", document: user.uid, field: "agreeWritings", data: [documentID])
            FirestoreManager().incrementData(collection: "Writings", document: documentID, field: "agree", increment: -1)
        }
        
        self.writing = writing
        recordTableView.reloadData()
    }
    
    func countAgreeRatio(agree: Int, disagree: Int) -> Float {
        return Float(agree) / (Float(agree) + Float(disagree))
    }
    
    func getResponse() {
        guard let documentID = writing?.documentID, let user = UserProvider.shared.userData else { return }
        
        ResponseProvider().getResponses(documentID: documentID, descending: false) { [weak self] (result) in
            
            switch result {
            case .success(let responsesData):
                self?.responses = responsesData.filter({ !user.blackList.contains($0.uid) })
                self?.recordTableView.reloadData()
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
        
        let docRef = FirestoreManager().db.collection("Writings").document(writing.documentID).collection("Responses").document()
        
        let data = ResponseData(documentID: docRef.documentID, date: Date(), uid: user.uid, userName: user.name, userImagePath: user.imagePath, response: response)
        
        FirestoreManager().addCustomData(docRef: docRef, data: data)
        
        FirestoreManager().incrementData(collection: "Writings", document: writing.documentID, field: "responseNumber", increment: 1)
        
        FirestoreManager().updateArrayData(collection: "Users", document: user.uid, field: "responseWritings", data: [writing.documentID])
        
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
    
    func blockAuthor() {
        
        guard let writing = writing, let user = UserProvider.shared.userData else { return }
        
        TTSwiftMessages().wait(title: "封鎖中")
        
        if !user.blackList.contains(writing.uid) {
            UserProvider.shared.userData?.blackList.append(writing.uid)
        }
        
        FirestoreManager().updateArrayData(collection: "Users", document: user.uid, field: "blackList", data: [writing.uid]) { [weak self] error in
            if let error = error {
                print("blockAuthor error: \(error)")
            }
            TTSwiftMessages().hideAll()
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    func blockResponser(uid: String) {
        
        guard var user = UserProvider.shared.userData else { return }
        
        TTSwiftMessages().wait(title: "封鎖中")
        
        if !user.blackList.contains(uid) {
            UserProvider.shared.userData?.blackList.append(uid)
            user.blackList.append(uid)
        }
        
        FirestoreManager().updateArrayData(collection: "Users", document: user.uid, field: "blackList", data: [uid]) { [weak self] error in
            guard let strongSelf = self else { return }
            
            if let error = error {
                print("blockAuthor error: \(error)")
            }
            TTSwiftMessages().hideAll()
            self?.responses = strongSelf.responses.filter({ !user.blackList.contains($0.uid) })
            self?.recordTableView.reloadData()
        }
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
            return cells.count
        } else {
            return responses.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            
            guard let writing = writing else { return UITableViewCell() }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: cells[indexPath.row].identifier, for: indexPath)
            
            cells[indexPath.row].setCell(tableViewCell: cell, writing: writing, agreeMethod: { [weak self] in self?.agree() }, disagreeMethod: { [weak self] in self?.disagree() })
            
            return cell
            
        } else {
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "RecordContentResponseTableViewCell") as? RecordContentResponseTableViewCell else { return UITableViewCell() }
            
            cell.response = responses[indexPath.row]
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return CGFloat.leastNormalMagnitude
        }
        return tableView.sectionHeaderHeight
    }

}

extension RecordContentViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if let cell = cell as? RecordContentTopTableViewCell, let writing = writing {
                let agreeRatio = CGFloat(countAgreeRatio(agree: writing.agree, disagree: writing.disagree))
                
                cell.agreeRatioView.frame.size.width = 0
                
                let animator = UIViewPropertyAnimator(duration: 1.5, curve: .easeInOut) { [weak self] in
                    cell.agreeRatioWidthConstraint.constant =  cell.agreeRatioBackgroundView.frame.width * agreeRatio
                    self?.view.layoutIfNeeded()
                }
                animator.startAnimation()
                
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.contentView.backgroundColor = UIColor.white
        header.textLabel?.font = UIFont(name: "NotoSansTC-Bold", size: 22)
        header.textLabel?.textColor = UIColor.SUMI
        //        header.textLabel?.textAlignment = .center
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let responseUid = responses[indexPath.row].uid
            if UserProvider.shared.userData?.uid == responseUid {
                return
            }
            
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            //        let seeAction = UIAlertAction(title: "查看留言者", style: .default) { (action) in
            //
            //        }
            let reportAction = UIAlertAction(title: "檢舉留言", style: .default) { _ in
                TTSwiftMessages().question(title: "檢舉留言", body: "確定要檢舉這則留言？", leftButtonTitle: "取消", rightButtonTitle: "確定", rightHandler: {
                    
                    TTSwiftMessages().show(color: UIColor.SUMI!, icon: UIImage.asset(.Icon_32px_Success_White)!, title: "檢舉已收到", body: "將會盡快處理您的檢舉\n如果不想看到留言\n請選擇封鎖留言者", duration: 3)
                })
            }
            let blockAction = UIAlertAction(title: "封鎖留言者", style: .default) { [weak self] _ in
                
                TTSwiftMessages().question(title: "封鎖留言者", body: "不再顯示該留言者的文章和留言\n確定要封鎖留言者？", leftButtonTitle: "取消", rightButtonTitle: "確定", rightHandler: {
                    
                    self?.blockResponser(uid: responseUid)
                })
            }
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alertController.addAction(reportAction)
            alertController.addAction(blockAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true)
        }
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
        responseButton.setTitle("留言", for: .normal)
        view.layoutIfNeeded()
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut, animations: { [weak self] in
            self?.responseBackgroundHeightConstraint.constant = 48
            self?.view.layoutIfNeeded()
        })
        animator.startAnimation()
    }
}
