//
//  CheckResponseTableViewCell.swift
//  Tastopia
//
//  Created by FISH on 2020/2/7.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class CheckResponseTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var responseView: UIView!
    @IBOutlet weak var responseLabel: UILabel!
    
    var response: ResponseData? {
        didSet {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            if let date = response?.date {
                dateLabel.text = formatter.string(from: date)
            }
            nameLabel.text = response?.userName
            responseLabel.text = response?.response
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        responseView.layer.cornerRadius = 5
        responseView.layer.shadowColor = UIColor.SUMI?.cgColor
        responseView.layer.shadowOffset = CGSize(width: 0, height: 3)
        responseView.layer.shadowRadius = 3
        responseView.layer.shadowOpacity = 0.3

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
