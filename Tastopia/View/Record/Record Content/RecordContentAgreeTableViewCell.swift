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
    
    var documentID: String? {
        didSet {
            guard let documentID = documentID, let user = UserProvider.shared.userData else { return }
            if user.agreeWritings.contains(documentID) {
                agreeButton.backgroundColor = UIColor.SUMI
                agreeButton.setTitleColor(UIColor.white, for: .normal)
                agreeButton.tintColor = UIColor.white
            } else {
                agreeButton.backgroundColor = UIColor.SHIRONEZUMI
                agreeButton.setTitleColor(UIColor.white, for: .normal)
                agreeButton.tintColor = UIColor.white
            }
            if user.disagreeWritings.contains(documentID) {
                disagreeButton.backgroundColor = UIColor.SUMI
                disagreeButton.setTitleColor(UIColor.white, for: .normal)
                disagreeButton.tintColor = UIColor.white
            } else {
                disagreeButton.backgroundColor = UIColor.SHIRONEZUMI
                disagreeButton.setTitleColor(UIColor.white, for: .normal)
                disagreeButton.tintColor = UIColor.white
            }
        }
    }
    
    var agree: (() -> Void)?
    
    var disagree: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        agreeButton.layer.cornerRadius = 16
        disagreeButton.layer.cornerRadius = 16
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func agreeButtonPressed(_ sender: UIButton) {
        agree?()
    }
    
    @IBAction func disagreeButtonPressed(_ sender: UIButton) {
        disagree?()
    }
    
}
