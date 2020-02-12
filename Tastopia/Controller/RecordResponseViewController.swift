//
//  RecordResponseViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/6.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class RecordResponseViewController: UIViewController {
    
    @IBOutlet weak var responseView: UIView!
    @IBOutlet weak var responseViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var responseTextViewBackgroundView: UIView!
    @IBOutlet weak var responseTextView: UITextView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    
    var writing: WritingData?
    
    var passResponse: ((ResponseData) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        responseView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        responseView.layer.cornerRadius = 16
        responseView.layer.shadowColor = UIColor.SUMI?.cgColor
        //responseView.layer.shadowOffset = CGSize(width: 0, height: 5)
        responseView.layer.shadowRadius = 3
        responseView.layer.shadowOpacity = 0.3
        
        responseViewBottomConstraint.constant = responseView.frame.height
        
        responseTextViewBackgroundView.layer.cornerRadius = 16
        responseTextViewBackgroundView.layer.shadowColor = UIColor.SUMI?.cgColor
        responseTextViewBackgroundView.layer.shadowOffset = CGSize(width: 0, height: 5)
        responseTextViewBackgroundView.layer.shadowRadius = 5
        responseTextViewBackgroundView.layer.shadowOpacity = 0.3
        
        cancelButton.layer.cornerRadius = 5
        sendButton.layer.cornerRadius = 5
        
        view.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showResponseView()
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        closeResponseView()
    }
    
    @IBAction func sendButtonPressed(_ sender: UIButton) {
        guard let writing = writing, let uid = UserProvider.shared.uid, let name = UserProvider.shared.name, let response = responseTextView.text else { return }
        
        if response == "" {
            // response is empty
            return
        }
        
        let docRef = FirestoreManager.shared.db.collection("Writings").document(writing.documentID).collection("Responses").document()
        let data = ResponseData(documentID: docRef.documentID, date: Date(), uid: uid, userName: name, response: response)
        FirestoreManager.shared.addCustomData(docRef: docRef, data: data)
        
        FirestoreManager.shared.incrementData(collection: "Writings", document: writing.documentID, field: "responseNumber", increment: 1)
        
        FirestoreManager.shared.updateArrayData(collection: "Users", document: uid, field: "responseWritings", data: [writing.documentID])
        
        passResponse?(data)
        
        closeResponseView()
    }
    
    func showResponseView() {
        let animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeInOut) { [weak self] in
            self?.responseViewBottomConstraint.constant = 0
            self?.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }
    
    func closeResponseView() {
        let animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeInOut) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.responseViewBottomConstraint.constant = strongSelf.responseView.frame.height
            strongSelf.view.layoutIfNeeded()
        }
        animator.addCompletion { [weak self] _ in
            self?.dismiss(animated: false, completion: nil)
        }
        animator.startAnimation()
    }
    
}
