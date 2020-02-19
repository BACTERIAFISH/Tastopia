//
//  QRcodeViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/15.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class QRCodeViewController: UIViewController {
    
    @IBOutlet weak var containView: UIView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    var task: TaskData?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        containView.layer.cornerRadius = 16
        containView.layer.createTTBorder()

        if let task = task {
            let image = generateQRCode(from: task.taskID)
            imageView.image = image
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        dismiss(animated: false, completion: nil)
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }

}
