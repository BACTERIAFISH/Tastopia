//
//  TaskRecordCollectionViewCell.swift
//  Tastopia
//
//  Created by FISH on 2020/2/4.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class TaskRecordCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var sortView: UIView!
    
    @IBOutlet weak var sortLabel: UILabel!
    
    @IBOutlet weak var commentImageView: UIImageView!
    
    override func awakeFromNib() {
        sortView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        sortView.layer.cornerRadius = 18
    }
}
