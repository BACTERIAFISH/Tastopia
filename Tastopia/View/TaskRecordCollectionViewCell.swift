//
//  TaskRecordCollectionViewCell.swift
//  Tastopia
//
//  Created by FISH on 2020/2/4.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit
import AVFoundation

class TaskRecordCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var movieView: UIView! 
    
    @IBOutlet weak var sortView: UIView!
    
    @IBOutlet weak var sortLabel: UILabel!
    
    @IBOutlet weak var commentImageView: UIImageView!
    
    var urlString: String? {
        didSet {
            if let urlString = urlString {
                playMovie(urlString: urlString)
            }
        }
    }
    
    var playerLooper: AVPlayerLooper?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        sortView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        sortView.layer.cornerRadius = 18
                
    }
    
    func playMovie(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let player = AVQueuePlayer()
        player.isMuted = true
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
