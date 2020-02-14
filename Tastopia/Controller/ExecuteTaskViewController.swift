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
    
    var map: GMSMapView?
    
    var selectedMedias = [TTMediaData]()
    
    var playerLoopers = [AVPlayerLooper]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        compositionShadowView.layer.cornerRadius = 5
        compositionShadowView.layer.createTTBorder()
        
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        
        submitButton.layer.cornerRadius = 5
        
        if let task = task {
            peopleLabel.text = String(task.people)
            mediaLabel.text = String(task.media)
            compositionLabel.text = String(task.composition)
        }
        
//        checkTask()
        
    }
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submit(_ sender: UIButton) {
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
        
        guard let location = map?.myLocation, let restaurant = restaurant else { return }
        
        let taskLatitude = restaurant.position.latitude
        let taskLongitude = restaurant.position.longitude
        
        guard let latitudeDegree = CLLocationDegrees(exactly: taskLatitude), let longitudeDegree = CLLocationDegrees(exactly: taskLongitude) else { return }
        
        let distanceMeter = location.distance(from: CLLocation(latitude: latitudeDegree, longitude: longitudeDegree))
        
        if distanceMeter > 10 {
            // distance > 10 meters
            return
        }
        
    }
    
    func submitTask() {
        guard let compositionText = compositionTextView.text else { return }
        
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
        
        guard let restaurant = restaurant, let uid = UserProvider.shared.uid, let name = UserProvider.shared.name else { return }
        
        group.notify(queue: .main) { [weak self] in
            guard let strongSelf = self else { return }
            
            var urlStrings = [String]()
            var mediaTypes = [String]()
            for media in strongSelf.selectedMedias {
                urlStrings.append(media.urlString)
                mediaTypes.append(media.mediaType)
            }
            
            let docRef = FirestoreManager.shared.db.collection("Writings").document()
            let data = WritingData(documentID: docRef.documentID, date: Date(), number: restaurant.number, uid: uid, userName: name, composition: compositionText, medias: urlStrings, mediaTypes: mediaTypes, agree: 1, disagree: 0, responseNumber: 0)
            FirestoreManager.shared.addCustomData(docRef: docRef, data: data)
            self?.dismiss(animated: false, completion: nil)
        }
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
                let player = AVQueuePlayer()
                let playerItem = AVPlayerItem(url: url)
                let playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
                playerLoopers.append(playerLooper)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.videoGravity = .resizeAspectFill
                playerLayer.frame = cell.movieView.bounds
                cell.movieView.layer.addSublayer(playerLayer)
                player.play()
            }
            
            cell.layer.cornerRadius = 5
            cell.layer.createTTBorder()
            return cell
            
        } else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExecuteTaskAddCollectionViewCell", for: indexPath)
            cell.layer.cornerRadius = 5
            cell.layer.createTTBorder()
            
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

extension ExecuteTaskViewController: UIImagePickerControllerDelegate {
    
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

extension ExecuteTaskViewController: UINavigationControllerDelegate {
    
}

struct TTMediaData {
    var mediaType: String
    var urlString: String = ""
    var url: URL?
    var image: UIImage?
}
