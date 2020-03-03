//
//  SelectImageCollectionViewCell.swift
//  Tastopia
//
//  Created by FISH on 2020/2/20.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class SelectImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var countView: UIView!
    
    @IBOutlet weak var countLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        countView.layer.cornerRadius = 16
        countView.layer.borderColor = UIColor.white.cgColor
    }
    
}
