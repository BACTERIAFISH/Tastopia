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
    @IBOutlet weak var responseTextView: UITextView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    
    var writing: WritingData?
    
    var passResponse: ((ResponseData) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        responseViewBottomConstraint.constant = responseView.frame.height
        view.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showResponseView()
    }

    func showResponseView() {
        let animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeInOut) { [weak self] in
            self?.responseViewBottomConstraint.constant = 0
            self?.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        dismiss(animated: false, completion: nil)
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
        
        dismiss(animated: false, completion: nil)
    }
}
