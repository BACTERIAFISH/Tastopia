//
//  SelectImageDisplayCollectionViewCell.swift
//  Tastopia
//
//  Created by FISH on 2020/2/20.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class SelectImageDisplayCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.layer.cornerRadius = 16
    }
}
