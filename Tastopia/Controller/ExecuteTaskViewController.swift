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
    
    var map: GMSMapView?
    
    var selectedMedias = [TTMediaData]()
    
    var playerLoopers = [AVPlayerLooper]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        compositionTextView.delegate = self
        
        compositionShadowView.layer.cornerRadius = 16
        compositionShadowView.layer.createTTBorder()
        
        submitButton.layer.cornerRadius = 16
        
        compositionTextView.selectedTextRange = compositionTextView.textRange(from: compositionTextView.beginningOfDocument, to: compositionTextView.endOfDocument)
        
        if let task = task {
            peopleLabel.text = String(task.people)
            mediaLabel.text = String(task.media)
            compositionLabel.text = String(task.composition)
        }
        
    }
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submit(_ sender: UIButton) {
        //        checkTask()
        submitTask()
    }
    
    func openImagePicker() {
        let ac = UIAlertController(title: "新增照片從...", message: nil, preferredStyle: .actionSheet)
        let titles = ["Photo Library", "Camera", "Video"]
        for title in titles {
            let action = UIAlertAction(title: title, style: .default) { [weak self] (_) in
                
                let imagePicker = UIImagePickerController()
                switch title {
                case "Photo Library":
                    imagePicker.sourceType = .photoLibrary
                case "Camera":
                    imagePicker.sourceType = .camera
                case "Video":
                    imagePicker.sourceType = .camera
                    imagePicker.mediaTypes = [kUTTypeMovie as String]
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
    
    func checkTask() {
        
        guard let task = task, let composition = compositionTextView.text else { return }
        
        // composition fail
        if composition.trimmingCharacters(in: .whitespacesAndNewlines).count < task.composition {
            TTProgressHUD.shared.showFail(in: view, text: "字數不足")
            return
        }
        
        // media fail
        if selectedMedias.count < task.media {
            TTProgressHUD.shared.showFail(in: view, text: "照片、影片不足")
            return
        }
        
        guard let location = map?.myLocation, let restaurant = restaurant else { return }
        
        let distanceMeter = location.distance(from: CLLocation(latitude: restaurant.position.latitude, longitude: restaurant.position.longitude))
        
        // distance > 10 meters
        if distanceMeter > 10 {
            TTProgressHUD.shared.showFail(in: view, text: "地點錯誤")
            return
        }
        
        submitTask()
    }
    
    func submitTask() {
        TTProgressHUD.shared.showLoading(in: view, text: "上傳中")
        guard let restaurant = restaurant, let task = task, let user = UserProvider.shared.userData, let compositionText = compositionTextView.text else {
            TTProgressHUD.shared.hud.dismiss(animated: false)
            TTProgressHUD.shared.showFail(in: view, text: "上傳失敗")
            return
        }
        
        let group = DispatchGroup()
        for (i, media) in selectedMedias.enumerated() {
            group.enter()
            if media.mediaType == kUTTypeImage as String, let image = media.image {
                FirestoreManager.shared.uploadImage(image: image) { [weak self]  (result) in
                    switch result {
                    case .success(let urlString):
                        self?.selectedMedias[i].urlString = urlString
                        group.leave()
                    case .failure(let error):
                        print("submitTask error: \(error)")
                        group.leave()
                    }
                }
            } else if media.mediaType == kUTTypeMovie as String, let url = media.url {
                FirestoreManager.shared.uploadVideo(url: url) { [weak self] (result) in
                    switch result {
                    case .success(let urlString):
                        self?.selectedMedias[i].urlString = urlString
                        group.leave()
                    case .failure(let error):
                        print("submitTask error: \(error)")
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let strongSelf = self else { return }
            
            var urlStrings = [String]()
            var mediaTypes = [String]()
            for media in strongSelf.selectedMedias {
                urlStrings.append(media.urlString)
                mediaTypes.append(media.mediaType)
            }
            
            let docRef = FirestoreManager.shared.db.collection("Writings").document()
            let data = WritingData(documentID: docRef.documentID, date: Date(), number: restaurant.number, uid: user.uid, userName: user.name, composition: compositionText, medias: urlStrings, mediaTypes: mediaTypes, agree: 1, disagree: 0, responseNumber: 0, taskID: task.taskID)
            FirestoreManager.shared.addCustomData(docRef: docRef, data: data)
            
            strongSelf.changeTaskStatus()
            
            TTProgressHUD.shared.hud.dismiss(animated: false)
            TTProgressHUD.shared.showSuccess(in: strongSelf.view, text: "上傳成功")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                strongSelf.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func changeTaskStatus() {
        guard let user = UserProvider.shared.userData, var task = task else { return }
        task.status = 1
        passTask?(task)
        for i in 0..<UserProvider.shared.userTasks.count where UserProvider.shared.userTasks[i].documentID == task.documentID {
            UserProvider.shared.userTasks[i].status = 1
        }
        let ref = FirestoreManager.shared.db.collection("Users").document(user.uid).collection("Tasks").document(task.documentID)
        FirestoreManager.shared.addData(docRef: ref, data: ["status": 1])
    }
}

extension ExecuteTaskViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedMedias.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item != selectedMedias.count {
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExecuteTaskPhotoCollectionViewCell", for: indexPath) as? ExecuteTaskPhotoCollectionViewCell else { return UICollectionViewCell() }
            
            let media = selectedMedias[indexPath.item]
            
            if media.mediaType == kUTTypeImage as String {
                cell.imageView.image = media.image
            } else if media.mediaType == kUTTypeMovie as String, let url = media.url {
                cell.url = url
                //                let player = AVQueuePlayer()
                //                player.isMuted = true
                //                let playerItem = AVPlayerItem(url: url)
                //                let playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
                //                playerLoopers.append(playerLooper)
                //                let playerLayer = AVPlayerLayer(player: player)
                //                playerLayer.videoGravity = .resizeAspectFill
                //                playerLayer.frame = cell.movieView.bounds
                //                cell.movieView.layer.addSublayer(playerLayer)
                //                player.play()
            }
            
            //            cell.layer.cornerRadius = 5
            //            cell.layer.createTTBorder()
            return cell
            
        } else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExecuteTaskAddCollectionViewCell", for: indexPath)
            cell.layer.cornerRadius = 16
            //            cell.layer.createTTBorder()
            
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
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Combine the textView text and the replacement text to
        // create the updated text string
        let currentText: String = textView.text
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
        
        // If updated text view will be empty, add the placeholder
        // and set the cursor to the beginning of the text view
        if updatedText.isEmpty {
            
            textView.text = "寫下你的感想"
            textView.textColor = UIColor.SHIRONEZUMI
            
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
        }
            
            // Else if the text view's placeholder is showing and the
            // length of the replacement string is greater than 0, set
            // the text color to black then set its text to the
            // replacement string
        else if textView.textColor == UIColor.SHIRONEZUMI && !text.isEmpty {
            textView.textColor = UIColor.SUMI
            textView.text = text
        }
            
            // For every other case, the text should change with the usual
            // behavior...
        else {
            return true
        }
        
        // ...otherwise return false since the updates have already
        // been made
        return false
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.view.window != nil {
            if textView.textColor == UIColor.SHIRONEZUMI {
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            }
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

struct TTMediaData {
    var mediaType: String
    var urlString: String = ""
    var url: URL?
    var image: UIImage?
}
