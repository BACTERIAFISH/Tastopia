//
//  QuestionView.swift
//  Tastopia
//
//  Created by FISH on 2020/2/22.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class QuestionView: UIView {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    var leftHandler: ((UIButton) -> Void)?
    
    var rightHandler: ((UIButton) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @IBAction func leftButtonPressed(_ sender: UIButton) {
        leftHandler?(sender)
    }
    
    @IBAction func rightButtonPressed(_ sender: UIButton) {
        rightHandler?(sender)
    }

}
