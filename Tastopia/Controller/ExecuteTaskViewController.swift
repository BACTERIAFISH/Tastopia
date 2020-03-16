//
//  ExecuteTaskViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/3.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation
import GoogleMaps

class ExecuteTaskViewController: UIViewController {
    
    @IBOutlet weak var peopleLabel: UILabel!
    @IBOutlet weak var mediaLabel: UILabel!
    @IBOutlet weak var compositionLabel: UILabel!
    @IBOutlet weak var compositionShadowView: UIView!
    @IBOutlet weak var compositionTextView: UITextView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var submitButton: UIButton!
    
    var restaurant: Restaurant?
    
    var task: TaskData?
    
    var passTask: ((TaskData) -> Void)?
    
    var setStatusImage: (() -> Void)?
    
    var map: GMSMapView?
    
    var selectedMedias = [TTMediaData]()
    
    var playerLoopers = [AVPlayerLooper]()
    
    let firestoreManager = FirestoreManager()
    
    let writingProvider = WritingProvider()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setBeginLayout()
    }
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submit(_ sender: UIButton) {
        if isForTest() {
            submitTask()
        } else {
            checkTask()
        }
    }
    
    private func setBeginLayout() {
        
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        compositionTextView.delegate = self
        
        compositionShadowView.layer.cornerRadius = 16
        compositionShadowView.layer.createTTBorder()
        
        submitButton.layer.cornerRadius = 16
        
        if let task = task {
            peopleLabel.text = String(task.people)
            mediaLabel.text = String(task.media)
            compositionLabel.text = String(task.composition)
        }
    }
    
    private func openImagePicker() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let action = UIAlertAction(title: "圖庫", style: .default) { [weak self] (_) in
            
            guard let selectImageVC = self?.storyboard?.instantiateViewController(withIdentifier: TTConstant.ViewControllerID.selectImageViewController) as? SelectImageViewController else { return }
            
            selectImageVC.modalPresentationStyle = .overCurrentContext
            
            selectImageVC.passSelectedImages = { [weak self] images in
                
                guard let strongSelf = self else { return }
                
                for image in images {
                    let media = TTMediaData(mediaType: kUTTypeImage as String, image: image)
                    strongSelf.selectedMedias.append(media)
                }
                
                strongSelf.photoCollectionView.reloadData()
                
                strongSelf.photoCollectionView.scrollToItem(at: IndexPath(item: strongSelf.selectedMedias.count, section: 0), at: .centeredHorizontally, animated: true)
            }
            
            self?.present(selectImageVC, animated: true)
        }
        
        alertController.addAction(action)
        
        let titles = [TTConstant.photo, TTConstant.video]
        
        for title in titles {
            let action = UIAlertAction(title: title, style: .default) { [weak self] (_) in
                
                let imagePicker = UIImagePickerController()
                switch title {
                case TTConstant.photo:
                    imagePicker.sourceType = .camera
                case TTConstant.video:
                    imagePicker.sourceType = .camera
                    imagePicker.mediaTypes = [kUTTypeMovie as String]
                default:
                    imagePicker.sourceType = .photoLibrary
                }
                imagePicker.delegate = self
                self?.present(imagePicker, animated: true)
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    private func isForTest() -> Bool {
        var isTester = false
        var hasKeyword = false
        let testers = TastopiaTest.shared.testers
        let keyword = TastopiaTest.shared.keyword
        
        guard let user = UserProvider.shared.userData, let composition = compositionTextView.text else { return false }
        
        if testers.contains(user.email) {
            isTester = true
        }
        
        let range = NSRange(location: 0, length: composition.utf16.count)
        do {
            let regex = try NSRegularExpression(pattern: keyword)
            if regex.firstMatch(in: composition, options: [], range: range) != nil {
                hasKeyword = true
            }
            
        } catch {
            print("isForTest regex error: \(error)")
        }
        
        return isTester && hasKeyword
    }
    
    private func checkTask() {
        
        guard let task = task, let composition = compositionTextView.text else { return }
        
        if composition.trimmingCharacters(in: .whitespacesAndNewlines).utf16.count < task.composition {
            TTSwiftMessages().show(color: UIColor.AKABENI!, icon: UIImage.asset(.Icon_32px_Error_White)!, title: "上傳失敗", body: "字數不足")
            return
        }
        
        if selectedMedias.count < task.media {
            TTSwiftMessages().show(color: UIColor.AKABENI!, icon: UIImage.asset(.Icon_32px_Error_White)!, title: "上傳失敗", body: "照片、影片不足")
            return
        }
        
        guard let location = map?.myLocation, let restaurant = restaurant else { return }
        
        let distanceMeter = location.distance(from: CLLocation(latitude: restaurant.position.latitude, longitude: restaurant.position.longitude))
        
        if distanceMeter > 10, task.restaurantNumber != 0 {
            TTSwiftMessages().show(color: UIColor.AKABENI!, icon: UIImage.asset(.Icon_32px_Error_White)!, title: "上傳失敗", body: "地點錯誤")
            return
        }
        
        submitTask()
    }
    
    private func submitTask() {
        
        TTSwiftMessages().wait(title: "上傳中")
        
        guard let task = task, let user = UserProvider.shared.userData, let compositionText = compositionTextView.text else { return }
        
        writingProvider.uploadWriting(selectedMedias: selectedMedias, user: user, task: task, composition: compositionText) { [weak self] in
            
            self?.changeTaskStatus()
            
            TTSwiftMessages().hide()
            
            self?.dismiss(animated: true, completion: { [weak self] in
                TTSwiftMessages().show(color: UIColor.SUMI!, icon: UIImage.asset(.Icon_32px_Success_White)!, title: "上傳成功", body: "")
                self?.setStatusImage?()
            })
        }
        
    }
    
    private func changeTaskStatus() {
        guard var task = task else { return }
        
        task.status = TTTaskStstus.submitted.rawValue
        passTask?(task)
        
        TaskProvider.shared.changeTaskStatus(task: task, status: .submitted)
    }
    
}

extension ExecuteTaskViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedMedias.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item != selectedMedias.count {
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TTConstant.CellIdentifier.executeTaskPhotoCollectionViewCell, for: indexPath) as? ExecuteTaskPhotoCollectionViewCell else { return UICollectionViewCell() }
            
            cell.imageView.image = UIImage.asset(.Image_Tastopia_01_square)
            cell.playerLooper = nil
            
            let media = selectedMedias[indexPath.item]
            
            if media.mediaType == kUTTypeImage as String {
                cell.imageView.image = media.image
            } else if media.mediaType == kUTTypeMovie as String, let url = media.url {
                cell.url = url
            }
            
            cell.deleteImage = { [weak self] cell in
                if let deleteIndexPath = self?.photoCollectionView.indexPath(for: cell) {
                    self?.selectedMedias.remove(at: deleteIndexPath.item)
                    self?.photoCollectionView.deleteItems(at: [deleteIndexPath])
                }
            }

            return cell
            
        } else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TTConstant.CellIdentifier.executeTaskAddCollectionViewCell, for: indexPath)
            
            return cell
        }
        
    }
    
}

extension ExecuteTaskViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == selectedMedias.count {
            openImagePicker()
        }
    }
}

extension ExecuteTaskViewController: UITextViewDelegate {
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView.text == "寫下你的感想" && textView.textColor == UIColor.SHIRONEZUMI {
            
            textView.text = ""
            textView.textColor = .black
        }
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = "寫下你的感想"
            textView.textColor = UIColor.SHIRONEZUMI
        }
    }
    
}

extension ExecuteTaskViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let mediaType = info[.mediaType] as? String else { return }
        
        if mediaType == kUTTypeImage as String {
            if let image = info[.originalImage] as? UIImage {
                let media = TTMediaData(mediaType: mediaType, image: image)
                selectedMedias.append(media)
                photoCollectionView.reloadData()
                photoCollectionView.scrollToItem(at: IndexPath(item: selectedMedias.count, section: 0), at: .centeredHorizontally, animated: true)
            }
        } else if mediaType == kUTTypeMovie as String {
            if let url = info[.mediaURL] as? URL {
                let media = TTMediaData(mediaType: mediaType, url: url)
                selectedMedias.append(media)
                photoCollectionView.reloadData()
                photoCollectionView.scrollToItem(at: IndexPath(item: selectedMedias.count, section: 0), at: .centeredHorizontally, animated: true)
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
}
