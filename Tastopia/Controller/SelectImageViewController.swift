//
//  SelectImageViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/20.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit
import Photos

class SelectImageViewController: UIViewController {
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var selectedLabel: UILabel!
    @IBOutlet weak var displayCollectionView: UICollectionView!
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var displayPageControl: UIPageControl!
    
    var images: [UIImage] = []
    
    var selectedImages: [UIImage] = []
    
    var passSelectedImages: (([UIImage]) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayCollectionView.dataSource = self
        displayCollectionView.delegate = self
        imageCollectionView.dataSource = self
        imageCollectionView.delegate = self
        
        displayPageControl.numberOfPages = selectedImages.count
        
        grabPhotos()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        passSelectedImages?(selectedImages)
    }
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    func grabPhotos() {
        
        let imgManager = PHImageManager.default()
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        //        fetchOptions.fetchLimit = 1
        
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        if fetchResult.count > 0 {
            
            for i in 0..<fetchResult.count {
                
                imgManager.requestImage(for: fetchResult.object(at: i), targetSize: CGSize(width: 500, height: 500), contentMode: .aspectFill, options: requestOptions) { [weak self] (image, _) in
                    
                    if let image = image {
                        self?.images.append(image)
                    } else {
                        print("grabPhotos: no image")
                    }
                }
            }
            
        } else {
            print("grabPhotos: no photos")
        }
        
    }
}

extension SelectImageViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if collectionView == displayCollectionView {
            let height = displayCollectionView.frame.height - 40
            return CGSize(width: height, height: height)
        } else {
            let width = view.frame.width
            return CGSize(width: width / 3 - 2, height: width / 3 - 2)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        if collectionView == displayCollectionView {
            let space = (displayCollectionView.frame.width - (displayCollectionView.frame.height - 40)) / 2
            return UIEdgeInsets(top: 20, left: space, bottom: 20, right: space)
        } else {
            return UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        if collectionView == displayCollectionView {
            let space = displayCollectionView.frame.width - (displayCollectionView.frame.height - 40)
            return space
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        if collectionView == displayCollectionView {
            return 0
        } else {
            return 1
        }
    }
    
}

extension SelectImageViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == displayCollectionView {
            return selectedImages.count
        } else {
            return images.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == displayCollectionView {
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectImageDisplayCollectionViewCell", for: indexPath) as? SelectImageDisplayCollectionViewCell else { return UICollectionViewCell() }
            
            cell.imageView.image = selectedImages[indexPath.item]
            
            return cell
            
        } else {
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectImageCollectionViewCell", for: indexPath) as? SelectImageCollectionViewCell else { return UICollectionViewCell() }
            
            cell.imageView.image = images[indexPath.item]
            
            if let index = selectedImages.firstIndex(of: images[indexPath.item]) {
                cell.countView.backgroundColor = UIColor.SUMI
                cell.countView.layer.borderWidth = 0
                cell.countLabel.isHidden = false
                cell.countLabel.text = String(index + 1)
            } else {
                cell.countView.backgroundColor = UIColor.clear
                cell.countView.layer.borderWidth = 2
                cell.countLabel.isHidden = true
            }
            
            return cell
        }
        
    }
    
}

extension SelectImageViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == imageCollectionView {
            if let index = selectedImages.firstIndex(of: images[indexPath.item]) {
                selectedImages.remove(at: index)
                if index < displayPageControl.currentPage {
                    displayPageControl.currentPage -= 1
                    displayCollectionView.scrollToItem(at: IndexPath(item: displayPageControl.currentPage, section: 0), at: .centeredHorizontally, animated: false)
                }
            } else {
                selectedImages.append(images[indexPath.item])
            }
            collectionView.reloadData()
            displayCollectionView.reloadData()
            displayPageControl.numberOfPages = selectedImages.count
            if selectedImages.isEmpty {
                doneButton.setImage(UIImage.asset(.Icon_24px_Left_Arrow), for: .normal)
                selectedLabel.isHidden = true
            } else {
                doneButton.setImage(UIImage.asset(.Icon_24px_Check), for: .normal)
                selectedLabel.isHidden = false
                selectedLabel.text = "\(selectedImages.count)張"
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        displayPageControl.currentPage = Int(scrollView.contentOffset.x / view.frame.width)
    }
}
