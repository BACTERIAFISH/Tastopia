//
//  RecordContentAgreeTableViewCell.swift
//  Tastopia
//
//  Created by FISH on 2020/2/11.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class RecordContentAgreeTableViewCell: UITableViewCell {

    @IBOutlet weak var agreeButton: UIButton!
    
    @IBOutlet weak var disagreeButton: UIButton!
    
    var agree: (() -> Void)?
    
    var disagree: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func agreeButtonPressed(_ sender: UIButton) {
        agree?()
        sender.isSelected.toggle()
    }
    
    @IBAction func disagreeButtonPressed(_ sender: UIButton) {
        disagree?()
        sender.isSelected.toggle()
    }
    
}
