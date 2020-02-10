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
    
    var restaurant: Restaurant?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        taskContentTableView.dataSource = self
        taskContentTableView.delegate = self
        
        taskContentTableView.layer.cornerRadius = 16
        taskContentTableView.contentInset.top = 16
        taskContentTableView.clipsToBounds = false
        taskContentTableView.layer.shadowColor = UIColor.SUMI?.cgColor
        taskContentTableView.layer.shadowOffset = CGSize(width: 0, height: 5)
        taskContentTableView.layer.shadowRadius = 5
        taskContentTableView.layer.shadowOpacity = 0.3
        
        requestCompanyButton.layer.cornerRadius = 5
        executeTaskButton.layer.cornerRadius = 5
        
    }
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func executeTask(_ sender: UIButton) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "ExecuteTaskViewController") as? ExecuteTaskViewController else { return }
        
        vc.restaurant = restaurant
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
}

extension TaskContentViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskContentTableViewCell", for: indexPath) as? TaskContentTableViewCell, let restaurant = restaurant else { return UITableViewCell() }
        
        switch indexPath.row {
        case 0:
            guard let titleCell = tableView.dequeueReusableCell(withIdentifier: "TaskContentTitleTableViewCell", for: indexPath) as? TaskContentTitleTableViewCell else { return UITableViewCell() }
            titleCell.titleLabel.text = restaurant.name
            return titleCell
        case 1:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Pin)
            cell.contentLabel.text = restaurant.address
        case 2:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Phone)
            cell.contentLabel.text = restaurant.phone
        case 3:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Add_User)
            cell.contentLabel.text = "1個人吃飯"
        case 4:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Photo_Camera)
            cell.contentLabel.text = "拍5張照片"
        case 5:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Edit)
            cell.contentLabel.text = "寫100字感想"
        default:
            return cell
        }
        
        return cell
    }
    
}

extension TaskContentViewController: UITableViewDelegate {
    
}
