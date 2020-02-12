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
            guard let documentID = documentID else { return }
            if UserProvider.shared.agreeWritings.contains(documentID) {
                agreeButton.backgroundColor = UIColor.SAKURA
                agreeButton.setTitleColor(UIColor.SUMI, for: .normal)
                agreeButton.tintColor = UIColor.SUMI
            } else {
                agreeButton.backgroundColor = UIColor.SHIRONEZUMI
                agreeButton.setTitleColor(UIColor.HAI, for: .normal)
                agreeButton.tintColor = UIColor.HAI
            }
            if UserProvider.shared.disagreeWritings.contains(documentID) {
                disagreeButton.backgroundColor = UIColor.SAKURA
                disagreeButton.setTitleColor(UIColor.SUMI, for: .normal)
                disagreeButton.tintColor = UIColor.SUMI
            } else {
                disagreeButton.backgroundColor = UIColor.SHIRONEZUMI
                disagreeButton.setTitleColor(UIColor.HAI, for: .normal)
                disagreeButton.tintColor = UIColor.HAI
            }
        }
    }
    
    var agree: (() -> Void)?
    
    var disagree: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        agreeButton.layer.cornerRadius = 5
        disagreeButton.layer.cornerRadius = 5
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
