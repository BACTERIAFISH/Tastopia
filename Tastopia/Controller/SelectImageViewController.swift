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
    @IBOutlet weak var imageCollectionViewTopConstraint: NSLayoutConstraint!
    
    var images: [UIImage] = []
    
    var selectedImages: [UIImage] = []
    
    var passSelectedImages: (([UIImage]) -> Void)?
    
    var fetchedPage = 0
    
    var fetchStartIndex = 0
    
    var fetchRange = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayCollectionView.dataSource = self
        displayCollectionView.delegate = self
        
        imageCollectionView.dataSource = self
        imageCollectionView.delegate = self
        
        displayPageControl.numberOfPages = selectedImages.count
        
        let height = view.frame.height
        let width = view.frame.width
        fetchRange = (Int(height / (width / 3)) + 1) * 3 * 2
        
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
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var fetchEndIndex = fetchStartIndex + fetchRange
        
        if fetchEndIndex > fetchResult.count {
            fetchEndIndex = fetchResult.count
        }
        
        if fetchResult.count > 0, fetchStartIndex != fetchEndIndex {
            
            for i in fetchStartIndex..<fetchEndIndex {
                imgManager.requestImage(for: fetchResult.object(at: i), targetSize: CGSize(width: 500, height: 500), contentMode: .aspectFill, options: requestOptions) { [weak self] (image, _) in
                    
                    if let image = image {
                        self?.images.append(image)
                    } else {
                        print("grabPhotos: no image")
                    }
                }
            }
            
            fetchStartIndex = fetchEndIndex
            imageCollectionView.reloadData()
            
        } else {
            print("grabPhotos: no photos")
        }
        
    }
    
    func toggleDisplayCollectionView() {
        
        if selectedImages.isEmpty {
            
            let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) { [weak self] in
                self?.imageCollectionViewTopConstraint.constant = 20
                self?.view.layoutIfNeeded()
            }
            animator.startAnimation()
            
        } else if imageCollectionViewTopConstraint.constant == 20 {
            
            let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut) { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.imageCollectionViewTopConstraint.constant = strongSelf.displayCollectionView.frame.height + 40
                strongSelf.view.layoutIfNeeded()
            }
            animator.startAnimation()
            
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
            toggleDisplayCollectionView()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == displayCollectionView {
            displayPageControl.currentPage = Int(scrollView.contentOffset.x / view.frame.width)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let page = Int(scrollView.contentOffset.y / view.frame.height)
        if page > fetchedPage {
            grabPhotos()
            fetchedPage = page
        }
        
    }
}
