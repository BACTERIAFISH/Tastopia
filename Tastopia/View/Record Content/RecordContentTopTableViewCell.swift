//
//  RecordContentTopTableViewCell.swift
//  Tastopia
//
//  Created by FISH on 2020/2/11.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class RecordContentTopTableViewCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var agreeRatioBackgroundView: UIView!
    @IBOutlet weak var agreeRatioView: UIView!
    @IBOutlet weak var agreeRatioWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var agreeRatioLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        agreeRatioBackgroundView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        agreeRatioBackgroundView.layer.cornerRadius = agreeRatioBackgroundView.frame.height / 2
        
        agreeRatioView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        agreeRatioView.layer.cornerRadius = agreeRatioBackgroundView.frame.height / 2
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
