//
//  ExecuteTaskPhotoCollectionViewCell.swift
//  Tastopia
//
//  Created by FISH on 2020/2/3.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit
import AVFoundation

class ExecuteTaskPhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var movieView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.layer.cornerRadius = 16
    }
    
    var url: URL? {
        didSet {
            if let url = url {
                playMovie(url: url)
            }
        }
    }
    
    var playerLooper: AVPlayerLooper?
    
    func playMovie(url: URL) {
        layoutIfNeeded()
        let player = AVQueuePlayer()
        let playerItem = AVPlayerItem(url: url)
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        let width = movieView.frame.width
        playerLayer.frame = CGRect(x: 0, y: 0, width: width, height: width)
        movieView.layer.addSublayer(playerLayer)
        player.play()
        movieView.isHidden = false
    }
}
