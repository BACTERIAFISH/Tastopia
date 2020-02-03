//
//  TaskContentViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/2.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit

class TaskContentViewController: UIViewController {
    
    @IBOutlet weak var taskContentTableView: UITableView!
    @IBOutlet weak var requestCompanyButton: UIButton!
    @IBOutlet weak var executeTaskButton: UIButton!
    
    var task: TaskData?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        taskContentTableView.dataSource = self
        taskContentTableView.delegate = self
        
        taskContentTableView.layer.cornerRadius = 16
        taskContentTableView.contentInset.top = 16
        requestCompanyButton.layer.cornerRadius = 5
        executeTaskButton.layer.cornerRadius = 5
        
    }
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension TaskContentViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskContentTableViewCell", for: indexPath) as? TaskContentTableViewCell, let task = task else { return UITableViewCell() }
        
        switch indexPath.row {
        case 0:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Star_Circle)
            cell.contentLabel.text = task.restaurant.name
        case 1:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Address_Pin)
            cell.contentLabel.text = task.restaurant.address
        case 2:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Phone_Call)
            cell.contentLabel.text = task.restaurant.phone
        case 3:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Person_Circle)
            cell.contentLabel.text = "1個人吃飯"
        case 4:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Camera)
            cell.contentLabel.text = "拍5張照片"
        case 5:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Pencil)
            cell.contentLabel.text = "寫100字心得"
        default:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Star_Circle)
        }
        
        return cell
    }
    
}

extension TaskContentViewController: UITableViewDelegate {
    
}
