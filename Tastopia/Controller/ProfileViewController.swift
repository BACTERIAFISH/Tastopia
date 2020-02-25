//
//  ProfileViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/24.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var tapView: UIView!
    
    @IBOutlet weak var backgroundView: UIView!
    
    @IBOutlet weak var backgroundViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var personalImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var infoButton: UIButton!
    
    @IBOutlet weak var signOutButton: UIButton!
    
    var user: UserData?
    
    var showGameGuide: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundViewTrailingConstraint.constant = -view.frame.width / 2

        backgroundView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        backgroundView.layer.cornerRadius = 16
        backgroundView.layer.createTTShadow(color: UIColor.SHIRONEZUMI!.cgColor, offset: CGSize(width: 2, height: 0), radius: 3, opacity: 1)
        infoButton.layer.cornerRadius = 16
        signOutButton.layer.cornerRadius = 16
        
        nameLabel.text = user?.name
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(back))
        tapView.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) { [weak self] in
            self?.backgroundViewTrailingConstraint.constant = 0
            self?.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }

    @IBAction func infoButtonPressed(_ sender: UIButton) {
        
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.backgroundViewTrailingConstraint.constant = -strongSelf.view.frame.width / 2
            strongSelf.view.layoutIfNeeded()
        }
        animator.addCompletion { [weak self] _ in
            self?.dismiss(animated: false) {
                self?.showGameGuide?()
            }
        }
        animator.startAnimation()
        
    }
    
    @IBAction func signOutButtonPressed(_ sender: UIButton) {
        UserProvider.shared.signOut()
    }
    
    @objc func back() {
        
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.backgroundViewTrailingConstraint.constant = -strongSelf.view.frame.width / 2
            strongSelf.view.layoutIfNeeded()
        }
        animator.addCompletion { [weak self] _ in
            self?.dismiss(animated: false, completion: nil)
        }
        animator.startAnimation()
    }
}
