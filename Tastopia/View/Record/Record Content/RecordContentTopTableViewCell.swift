//
//  RecordContentTopTableViewCell.swift
//  Tastopia
//
//  Created by FISH on 2020/2/11.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class RecordContentTopTableViewCell: UITableViewCell {

    @IBOutlet weak var authorImageContainView: UIView!
    @IBOutlet weak var authorImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var agreeRatioBackgroundView: UIView!
    @IBOutlet weak var agreeRatioView: UIView!
    @IBOutlet weak var agreeRatioWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var agreeRatioLabel: UILabel!
    
    var authorImagePath: String? {
        didSet {
            guard let urlString = authorImagePath else { return }
            authorImageView.loadImage(urlString, placeHolder: UIImage.asset(.Image_Tastopia_Placeholder))
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        agreeRatioBackgroundView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        agreeRatioBackgroundView.layer.cornerRadius = agreeRatioBackgroundView.frame.height / 2
        
//        agreeRatioView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        agreeRatioView.layer.cornerRadius = agreeRatioBackgroundView.frame.height / 2
        
        authorImageContainView.layer.cornerRadius = authorImageContainView.frame.width / 2
        authorImageContainView.layer.createTTBorder()
        
        authorImageView.layer.cornerRadius = authorImageView.frame.width / 2
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
