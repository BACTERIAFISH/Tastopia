//
//  ProfileViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/24.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit
import MobileCoreServices
import Kingfisher

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var tapView: UIView!
    
    @IBOutlet weak var backgroundView: UIView!
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var backgroundViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var personalContainView: UIView!
    
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
        
        backgroundImageView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        backgroundImageView.layer.cornerRadius = 16
        
        view.layoutIfNeeded()
        personalImageView.layer.cornerRadius = personalImageView.frame.width / 2
        personalContainView.layer.borderColor = UIColor.white.cgColor
        personalContainView.layer.borderWidth = 2
        personalContainView.layer.cornerRadius = personalContainView.frame.width / 2
        
        nameLabel.text = user?.name
        
        if let user = user {
            personalImageView.loadImage(user.imagePath, placeHolder: UIImage.asset(.Image_Tastopia_Placeholder))
            backgroundImageView.loadImage(user.imagePath, placeHolder: UIImage.asset(.Image_Tastopia_Placeholder))
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(back))
        tapView.addGestureRecognizer(tapGesture)
        
        setBlurEffect()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) { [weak self] in
            self?.backgroundViewTrailingConstraint.constant = 0
            self?.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }
    
    @IBAction func setPersonalImage(_ sender: UIButton) {
        openImagePicker()
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
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let storyboard = UIStoryboard(name: TTConstant.StoryboardName.login, bundle: nil)
        
        guard let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else { return }
        
        appDelegate.window?.rootViewController = loginVC
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
    
    func setBlurEffect() {
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        blurEffectView.frame = backgroundImageView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        backgroundImageView.addSubview(blurEffectView)
    }
    
    func openImagePicker() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let action1 = UIAlertAction(title: "圖庫", style: .default) { [weak self] (_) in
            guard let selectImageVC = self?.storyboard?.instantiateViewController(withIdentifier: "SelectImageViewController") as? SelectImageViewController else { return }
            
            selectImageVC.modalPresentationStyle = .overCurrentContext
            
            selectImageVC.isSelectUserImage = true
            selectImageVC.passSelectedImages = { [weak self] images in
                if !images.isEmpty {
                    self?.uploadUserImage(image: images[0])
                }
            }
            
            self?.present(selectImageVC, animated: true)
        }
        alertController.addAction(action1)
        
        let action2 = UIAlertAction(title: "相片", style: .default) { [weak self] (_) in
            
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .camera
            imagePicker.delegate = self
            self?.present(imagePicker, animated: true)
        }
        alertController.addAction(action2)
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    func uploadUserImage(image: UIImage) {
        
        guard let user = user else { return }
        
        TTSwiftMessages().wait(title: "照片更換中")
        
        FirestoreManager().uploadImage(image: image, fileName: user.uid) { [weak self] (result) in
            switch result {
            case .success:
                self?.personalImageView.image = image
                self?.backgroundImageView.image = image
                ImageCache.default.clearMemoryCache()
                ImageCache.default.clearDiskCache()
                
                TTSwiftMessages().hideAll()
                
            case .failure(let error):
                print("uploadUserImage error: \(error)")
            }
        }
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let mediaType = info[.mediaType] as? String else { return }
        
        if mediaType == kUTTypeImage as String {
            if let image = info[.originalImage] as? UIImage {
                uploadUserImage(image: image)
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
}
