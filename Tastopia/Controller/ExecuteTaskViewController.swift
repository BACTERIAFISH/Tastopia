//
//  ExecuteTaskViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/3.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class ExecuteTaskViewController: UIViewController {
    
    @IBOutlet weak var compositionShadowView: UIView!
    @IBOutlet weak var compositionTextView: UITextView!
    @IBOutlet weak var photoLabel: UILabel!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var submitButton: UIButton!
    
    var restaurant: Restaurant?
    
    let datePicker = UIDatePicker()
    
    var selectedImages = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        compositionShadowView.layer.cornerRadius = 16
        compositionShadowView.layer.shadowColor = UIColor.SUMI?.cgColor
        compositionShadowView.layer.shadowOffset = CGSize(width: 0, height: 5)
        compositionShadowView.layer.shadowRadius = 5
        compositionShadowView.layer.shadowOpacity = 0.3
        
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        
        submitButton.layer.cornerRadius = 5
    }

    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submit(_ sender: UIButton) {
        submitTask()
    }
    
    func openImagePicker() {
        let ac = UIAlertController(title: "新增照片從...", message: nil, preferredStyle: .actionSheet)
        let titles = ["Photo Library", "Saved Photos Album", "Camera"]
        for title in titles {
            let action = UIAlertAction(title: title, style: .default) { [weak self] (_) in
                
                let imagePicker = UIImagePickerController()
                switch title {
                case "Photo Library":
                    imagePicker.sourceType = .photoLibrary
                case "Saved Photos Album":
                    imagePicker.sourceType = .savedPhotosAlbum
                case "Camera":
                    imagePicker.sourceType = .camera
                default:
                    imagePicker.sourceType = .photoLibrary
                }
                imagePicker.delegate = self
                self?.present(imagePicker, animated: true)
            }
            ac.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        ac.addAction(cancelAction)
        present(ac, animated: true)
    }
    
    func submitTask() {
        guard let compositionText = compositionTextView.text else { return }
        
        var urlStrings = [String]()
        for _ in 0..<selectedImages.count {
            urlStrings.append("")
        }
        let group = DispatchGroup()
        for (i, image) in selectedImages.enumerated() {
            group.enter()
            FirestoreManager.shared.uploadImage(image: image) { (result) in
                switch result {
                case .success(let urlString):
                    urlStrings[i] = urlString
                    group.leave()
                case .failure(let error):
                    print("submitTask error: \(error)")
                    group.leave()
                }
            }
        }
        
        guard let restaurant = restaurant, let uid = UserProvider.shared.uid, let name = UserProvider.shared.name else { return }
        
        group.notify(queue: .main) { [weak self] in
            let docRef = FirestoreManager.shared.db.collection("Writings").document()
            let data = WritingData(documentID: docRef.documentID, date: Date(), number: restaurant.number, uid: uid, userName: name, composition: compositionText, images: urlStrings, agree: 1, disagree: 0, responseNumber: 0)
            FirestoreManager.shared.addCustomData(docRef: docRef, data: data)
            self?.dismiss(animated: false, completion: nil)
        }
    }
}

extension ExecuteTaskViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedImages.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == selectedImages.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExecuteTaskAddCollectionViewCell", for: indexPath)
            cell.clipsToBounds = false
            cell.layer.cornerRadius = 5
            cell.layer.shadowColor = UIColor.SUMI?.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 5)
            cell.layer.shadowRadius = 5
            cell.layer.shadowOpacity = 0.3
            
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExecuteTaskPhotoCollectionViewCell", for: indexPath) as? ExecuteTaskPhotoCollectionViewCell else { return UICollectionViewCell() }
            cell.clipsToBounds = false
            cell.layer.cornerRadius = 5
            cell.layer.shadowColor = UIColor.SUMI?.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 5)
            cell.layer.shadowRadius = 5
            cell.layer.shadowOpacity = 0.3
            
            cell.imageView.image = selectedImages[indexPath.item]
            return cell
        }
    }
    
}

extension ExecuteTaskViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == selectedImages.count {
            openImagePicker()
        }
    }
}

extension ExecuteTaskViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        selectedImages.append(image)
        photoCollectionView.reloadData()
        photoCollectionView.scrollToItem(at: IndexPath(item: selectedImages.count, section: 0), at: .right, animated: false)
//        photoCollectionView.scrollRectToVisible(CGRect(x: photoCollectionView.contentSize.width, y: photoCollectionView.contentSize.height, width: 1, height: 1), animated: false)
        dismiss(animated: true, completion: nil)
    }
}

extension ExecuteTaskViewController: UINavigationControllerDelegate {
    
}
