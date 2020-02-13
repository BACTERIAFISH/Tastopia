//
//  RecordContentImageTableViewCell.swift
//  Tastopia
//
//  Created by FISH on 2020/2/11.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation

class RecordContentImageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var imageCollectionView: UICollectionView!
    
    @IBOutlet weak var imagePageControl: UIPageControl!
    
    var writing: WritingData? {
        didSet {
            guard let writing = writing else { return }
            imagePageControl.numberOfPages = writing.medias.count
        }
    }
    
    var playerLoopers = [AVPlayerLooper]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageCollectionView.dataSource = self
        imageCollectionView.delegate = self
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func imagePageControlValueChanged(_ sender: UIPageControl) {
        imageCollectionView.scrollToItem(at: IndexPath(item: sender.currentPage, section: 0), at: .centeredHorizontally, animated: true)
    }
}

extension RecordContentImageTableViewCell: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = contentView.frame.width
        return CGSize(width: width, height: width - 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}

extension RecordContentImageTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let writing = writing else { return 0 }
        return writing.medias.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecordContentCollectionViewCell", for: indexPath) as? RecordContentCollectionViewCell, let writing = writing else { return UICollectionViewCell() }
        
        if writing.mediaTypes[indexPath.item] == kUTTypeImage as String {
            cell.imageView.loadImage(writing.medias[indexPath.item], placeHolder: UIImage.asset(.Icon_512px_Ramen))
        } else if writing.mediaTypes[indexPath.item] == kUTTypeMovie as String {
            if let url = URL(string: writing.medias[indexPath.item]) {
                let player = AVQueuePlayer()
                let playerItem = AVPlayerItem(url: url)
                let playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
                playerLoopers.append(playerLooper)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.videoGravity = .resizeAspectFill
                let width = contentView.frame.width - 80
                playerLayer.frame = CGRect(x: 0, y: 0, width: width, height: width)
                cell.movieView.layer.addSublayer(playerLayer)
                player.play()
            }
        }
        
        return cell
    }
    
}

extension RecordContentImageTableViewCell: UICollectionViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        imagePageControl.currentPage = Int(scrollView.contentOffset.x / contentView.frame.width)
    }
    
}
