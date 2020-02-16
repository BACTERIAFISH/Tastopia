//
//  TaskContentButtonTableViewCell.swift
//  Tastopia
//
//  Created by FISH on 2020/2/15.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class TaskContentButtonTableViewCell: UITableViewCell {
    
    @IBOutlet weak var showButton: UIButton!
    
    @IBOutlet weak var changeButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        showButton.layer.cornerRadius = 5
        changeButton.layer.cornerRadius = 5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func showButtonPressed(_ sender: UIButton) {
        
    }
    
    @IBAction func changeButtonPressed(_ sender: UIButton) {
    }

}
