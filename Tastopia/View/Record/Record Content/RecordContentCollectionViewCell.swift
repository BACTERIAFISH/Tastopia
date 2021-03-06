//
//  RecordContentCollectionViewCell.swift
//  Tastopia
//
//  Created by FISH on 2020/2/5.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit
import AVFoundation

class RecordContentCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var movieView: UIView!
    
    var urlString: String? {
        didSet {
            if let urlString = urlString {
                playMovie(urlString: urlString)
            }
        }
    }
    
    var player: AVQueuePlayer?
    
    var playerLooper: AVPlayerLooper?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.layer.cornerRadius = 16
    }
    
    func playMovie(urlString: String) {
        layoutIfNeeded()
        guard let url = URL(string: urlString) else { return }
//        movieView.isHidden = false
//        movieView.layer.cornerRadius = 16
        player = AVQueuePlayer()
        let playerItem = AVPlayerItem(url: url)
        playerLooper = AVPlayerLooper(player: player!, templateItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        let width = imageView.frame.width
        playerLayer.frame = CGRect(x: 0, y: 0, width: width, height: width)
        imageView.layer.addSublayer(playerLayer)
        player!.play()
    }
}
