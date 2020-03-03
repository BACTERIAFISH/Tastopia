//
//  RecordContentCompositionTableViewCell.swift
//  Tastopia
//
//  Created by FISH on 2020/2/11.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class RecordContentCompositionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var compositionView: UIView!
    
    @IBOutlet weak var compositionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        compositionView.layer.cornerRadius = 16
        compositionView.layer.createTTBorder()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
