//
//  ExecuteTaskViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/3.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class ExecuteTaskViewController: UIViewController {
    
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var compositionTextView: UITextView!
    @IBOutlet weak var photoLabel: UILabel!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var addPhotoButton: UIButton!
    
    var restaurant: Restaurant?
    
    let datePicker = UIDatePicker()
    
    var selectedImages = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        createDatePicker()
        dateTextField.inputView = datePicker
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateTextField.text = dateFormatter.string(from: Date())
        dateTextField.layer.cornerRadius = 5
        dateTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        dateTextField.leftViewMode = .always
        
        compositionTextView.layer.cornerRadius = 16
        addPhotoButton.layer.cornerRadius = 5
        
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        
    }

    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addPhoto(_ sender: UIButton) {
        openImagePicker()
    }
    
    @IBAction func submit(_ sender: UIButton) {
        submitTask()
    }
    
    func createDatePicker() {
        
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "zh-TW")
        datePicker.addTarget(self, action: #selector(changeDate), for: .valueChanged)
    }
    
    @objc func changeDate() {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateTextField.text = dateFormatter.string(from: datePicker.date)
    }
    
    func openImagePicker() {
        let ac = UIAlertController(title: "新增照片從...", message: nil, preferredStyle: .actionSheet)
        let titles = ["Photo Library", "Saved Photos Album", "Camera"]
        for title in titles {
            let action = UIAlertAction(title: title, style: .default) { [weak self] (action) in
                
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let dateText = dateTextField.text, let date = dateFormatter.date(from: dateText), let compositionText = compositionTextView.text else { return }
        
        let dateInt = Int(date.timeIntervalSince1970)
        
        var urlStrings = [String]()
        let group = DispatchGroup()
        for image in selectedImages {
            group.enter()
            FirestoreManager.shared.uploadImage(image: image) { (result) in
                switch result {
                case .success(let urlString):
                    urlStrings.append(urlString)
                    group.leave()
                case .failure(let error):
                    print("submitTask error: \(error)")
                    group.leave()
                }
            }
        }
        
        guard let restaurant = restaurant, let uid = UserProvider.shared.uid, let name = UserProvider.shared.name else { return }
        
        group.notify(queue: .main) { [weak self] in
            let uuid = NSUUID().uuidString
            let data = WritingData(documentID: uuid, number: restaurant.number, uid: uid, userName: name, date: dateInt, composition: compositionText, images: urlStrings, agree: 1, disagree: 0)
            FirestoreManager.shared.addCustomData(collection: "Writings", document: uuid, data: data)
            self?.dismiss(animated: true, completion: nil)
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
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExecuteTaskPhotoCollectionViewCell", for: indexPath) as? ExecuteTaskPhotoCollectionViewCell else { return UICollectionViewCell() }
            
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
        if !selectedImages.isEmpty, addPhotoButton.isHidden == false {
            addPhotoButton.isHidden = true
            photoLabel.isHidden = false
            photoCollectionView.isHidden = false
        }
        photoCollectionView.reloadData()
        dismiss(animated: true, completion: nil)
    }
}

extension ExecuteTaskViewController: UINavigationControllerDelegate {
    
}
