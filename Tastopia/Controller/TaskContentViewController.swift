//
//  TaskContentViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/2.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit
import GoogleMaps

class TaskContentViewController: UIViewController {
    
    @IBOutlet weak var taskContentTableView: UITableView!
    @IBOutlet weak var requestCompanyButton: UIButton!
    @IBOutlet weak var executeTaskButton: UIButton!
    
    var restaurant: Restaurant?
    var task: TaskData?
    
    var map: GMSMapView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        taskContentTableView.dataSource = self
        taskContentTableView.delegate = self
        
        taskContentTableView.layer.cornerRadius = 5
        taskContentTableView.contentInset.top = 16
        taskContentTableView.clipsToBounds = false
        taskContentTableView.layer.createTTBorder()
        
        requestCompanyButton.layer.cornerRadius = 5
        
        executeTaskButton.layer.cornerRadius = 5
        
        setTaskStatus()
        
    }
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func executeTask(_ sender: UIButton) {
        guard let task = task else { return }
        switch task.status {
        case 0:
            guard let vc = storyboard?.instantiateViewController(withIdentifier: "ExecuteTaskViewController") as? ExecuteTaskViewController else { return }
            
            vc.map = map
            vc.restaurant = restaurant
            vc.task = task
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
            
        case 1:
            // 確認任務
            // check writings where restaurant, taskID, date >= task.people
            guard let uid = UserProvider.shared.userData?.uid else { return }
            WritingProvider().checkTaskWritings(task: task) { [weak self] (result) in
                switch result {
                case .success(let pass):
                    if pass {
                        self?.task?.status = 2
                        for i in 0..<UserProvider.shared.userTasks.count where UserProvider.shared.userTasks[i].taskID == task.taskID {
                            UserProvider.shared.userTasks[i].status = 2
                        }
                        let ref = FirestoreManager.shared.db.collection("Users").document(uid).collection("Tasks").document(task.documentID)
                        ref.updateData(["status": 2])
                        self?.setTaskStatus()
                        
                        
                        // 檢查是否有存進 user finish task array
                        
                        // 如果沒有，存user finish task array
                        // taskNumber += 1
                        // 餐廳數量加一
                        
                    } else {
                        // 重新上傳任務按鈕開啟 case3
                        print("mission fail")
                    }
                    
                case .failure(let error):
                    print("checkTaskWritings error: \(error)")
                }
            }
        case 2:
            print("task status 2")
            // 接新任務
        default:
            print("task status error")
            return
        }
        
    }
    
    @IBAction func requestCompanyButtonPressed(_ sender: UIButton) {

    }
    
    func setTaskStatus() {
        guard let task = task else { return }
        switch task.status {
        case 0:
            executeTaskButton.setTitle("上傳任務", for: .normal)
        case 1:
            executeTaskButton.setTitle("確認任務", for: .normal)
        case 2:
            executeTaskButton.setTitle("接新任務", for: .normal)
        case 3:
            executeTaskButton.setTitle("確認任務", for: .normal)
        default:
            print("task status error")
            return
        }
    }
}

extension TaskContentViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskContentTableViewCell", for: indexPath) as? TaskContentTableViewCell, let restaurant = restaurant, let task = task else { return UITableViewCell() }
        
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
            cell.contentLabel.text = "\(task.people)個人吃飯"
        case 4:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Photo_Camera)
            cell.contentLabel.text = "拍攝照片或影片 x \(task.media)"
        case 5:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Edit)
            cell.contentLabel.text = "寫\(task.composition)字感想"
        default:
            return cell
        }
        
        return cell
    }
    
}

extension TaskContentViewController: UITableViewDelegate {
    
}
