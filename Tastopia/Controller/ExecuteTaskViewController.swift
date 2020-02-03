//
//  ExecuteTaskViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/3.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class ExecuteTaskViewController: UIViewController {
    
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var compositionTextView: UITextView!
    @IBOutlet weak var photoLabel: UILabel!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var addPhotoButton: UIButton!
    
    let datePicker = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        createDatePicker()
        dateTextField.inputView = datePicker
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateTextField.text = dateFormatter.string(from: Date())
        dateTextField.layer.cornerRadius = 5
        dateTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        dateTextField.leftViewMode = .always
        
        compositionTextView.layer.cornerRadius = 16
        addPhotoButton.layer.cornerRadius = 5
        
    }

    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addPhoto(_ sender: UIButton) {
        
    }
    
    func createDatePicker() {
        
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "zh-TW")
        datePicker.addTarget(self, action: #selector(changeDate), for: .valueChanged)
    }
    
    @objc func changeDate() {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateTextField.text = dateFormatter.string(from: datePicker.date)
    }
    
}
