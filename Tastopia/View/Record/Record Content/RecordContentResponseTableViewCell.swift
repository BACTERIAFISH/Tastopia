//
//  CheckResponseTableViewCell.swift
//  Tastopia
//
//  Created by FISH on 2020/2/7.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class RecordContentResponseTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userImageContainView: UIView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var responseView: UIView!
    @IBOutlet weak var responseLabel: UILabel!
    
    var response: ResponseData? {
        didSet {
            guard let response = response else { return }
            
            dateLabel.text = DateFormatter.createTTDate(date: response.date, format: "yyyy-MM-dd HH:mm")
            
            nameLabel.text = response.userName
            responseLabel.text = response.response
            userImageView.loadImage(response.userImagePath, placeHolder: UIImage.asset(.Image_Tastopia_Placeholder))
            
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        responseView.layer.cornerRadius = 5
        userImageContainView.layer.cornerRadius = userImageContainView.frame.width / 2
        userImageContainView.layer.createTTBorder()
        userImageView.layer.cornerRadius = userImageView.frame.width / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
