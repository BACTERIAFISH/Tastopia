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
        
        let responseID = FirestoreManager.shared.createDocumentID(collection: "Responses")
        let data = ResponseData(responseID: responseID, documentID: writing.documentID, uid: uid, userName: name, response: response)
        FirestoreManager.shared.addCustomData(collection: "Responses", document: responseID, data: data)
        dismiss(animated: false, completion: nil)
    }
}
