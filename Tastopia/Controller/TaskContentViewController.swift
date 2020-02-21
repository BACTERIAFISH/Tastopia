//
//  TaskContentViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/2/2.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase

class TaskContentViewController: UIViewController {
    
    @IBOutlet weak var taskContentTableView: UITableView!
    @IBOutlet weak var showQRCodeButton: UIButton!
    @IBOutlet weak var scanQRCodeButton: UIButton!
    @IBOutlet weak var requestCompanyButton: UIButton!
    @IBOutlet weak var executeTaskButton: UIButton!
    
    var restaurant: Restaurant?
    var task: TaskData?
    
    var passTask: ((TaskData?) -> Void)?
    
    var map: GMSMapView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        taskContentTableView.dataSource = self
        taskContentTableView.delegate = self
        
        taskContentTableView.layer.cornerRadius = 16
        taskContentTableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        taskContentTableView.layer.createTTBorder()
        
        showQRCodeButton.layer.cornerRadius = 16
        scanQRCodeButton.layer.cornerRadius = 16
        requestCompanyButton.layer.cornerRadius = 16
        executeTaskButton.layer.cornerRadius = 16
        
        setTaskStatus()
    }
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func showQRCode() {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "QRCodeViewController") as? QRCodeViewController, let task = task else { return }
        vc.modalPresentationStyle = .overCurrentContext
        vc.task = task
        present(vc, animated: false)
    }
    
    @IBAction func scanQRCode() {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "QRCodeScanViewController") as? QRCodeScanViewController else { return }
        vc.modalPresentationStyle = .overCurrentContext
        vc.passTaskID = { [weak self] newTaskID in
            guard let task = self?.task, let user = UserProvider.shared.userData else { return }
            let ref = FirestoreManager.shared.db.collection("Users").document(user.uid).collection("Tasks").document(task.documentID)
            ref.updateData(["taskID": newTaskID])
            for i in 0..<UserProvider.shared.userTasks.count where UserProvider.shared.userTasks[i].taskID == task.taskID {
                UserProvider.shared.userTasks[i].taskID = newTaskID
            }
            self?.task?.taskID = newTaskID
            self?.passTask?(self?.task)
            self?.taskContentTableView.reloadData()
        }
        vc.showHud = { [weak self] in
            guard let strongSelf = self else { return }
            TTProgressHUD.shared.showSuccess(in: strongSelf.view, text: "同步代碼成功")
        }
        present(vc, animated: true)
    }
    
    @IBAction func executeTask(_ sender: UIButton) {
        guard let task = task, let user = UserProvider.shared.userData else { return }
        switch task.status {
        case 0:
            
            if task.people > 1 {
                let ac = UIAlertController(title: "多人任務", message: "執行多人任務前記得要同步自己和同伴的任務代碼，不然確認任務時會失敗喔", preferredStyle: .alert)
                let action = UIAlertAction(title: "繼續上傳", style: .default) { [weak self] (_) in
                    self?.showExecuteTask()
                }
                let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                ac.addAction(action)
                ac.addAction(cancel)
                present(ac, animated: true)
            } else {
                showExecuteTask()
            }
            
        case 1:
            // 確認任務
            // check writings where restaurant, taskID, date >= task.people
            TTProgressHUD.shared.showLoading(in: view, text: "確認中")
            WritingProvider().checkTaskWritings(task: task) { [weak self] (result) in
                guard let strongSelf = self else { return }
                switch result {
                case .success(let pass):
                    if pass {
                        self?.task?.status = 2
                        for i in 0..<UserProvider.shared.userTasks.count where UserProvider.shared.userTasks[i].taskID == task.taskID {
                            UserProvider.shared.userTasks[i].status = 2
                        }
                        let ref = FirestoreManager.shared.db.collection("Users").document(user.uid).collection("Tasks").document(task.documentID)
                        ref.updateData(["status": 2])
                        self?.passTask?(self?.task)
                                
                        // 檢查是否有存進 user passRestaurant array
                        // 如果沒有，存user passRestaurant array
                        // taskNumber += 1
                        // add task in Tasks
                        if !user.passRestaurant.contains(task.restaurantNumber) {
                            UserProvider.shared.userData?.passRestaurant.append(task.restaurantNumber)
                            UserProvider.shared.userData?.taskNumber += 1
                            let ref = FirestoreManager.shared.db.collection("Users").document(user.uid)
                            FirestoreManager.shared.addData(docRef: ref, data: [
                                "taskNumber": user.taskNumber + 1,
                                "passRestaurant": FieldValue.arrayUnion([task.restaurantNumber])
                            ])
                            
                            UserProvider.shared.getTaskTypes { (result) in
                                switch result {
                                case .success(let taskTypes):
                                    guard let taskType = taskTypes.randomElement() else { return }
                                    let ref = FirestoreManager.shared.db.collection("Users").document(user.uid).collection("Tasks").document()
                                    let newTask = TaskData(documentID: ref.documentID, restaurantNumber: user.taskNumber + 3, people: taskType.people, media: taskType.media, composition: taskType.composition, status: 0, taskID: ref.documentID)
                                    FirestoreManager.shared.addCustomData(docRef: ref, data: newTask)
                                    
                                    UserProvider.shared.userTasks.append(newTask)
                                    
                                    NotificationCenter.default.post(name: NSNotification.Name("addRestaurant"), object: nil)
                                case .failure(let error):
                                    print("getTaskTypes error: \(error)")
                                }
                            }
                        }
                        
                        TTProgressHUD.shared.hud.dismiss(animated: false)
                        TTProgressHUD.shared.showSuccess(in: strongSelf.view, text: "確認成功")
                        
                        self?.setTaskStatus()
                        
                    } else {
                        // show mission fail
                        TTProgressHUD.shared.hud.dismiss(animated: false)
                        TTProgressHUD.shared.showFail(in: strongSelf.view, text: "確認失敗")
                    }
                    
                case .failure(let error):
                    print("checkTaskWritings error: \(error)")
                }
            }
        case 2:
            // 接新任務
            // create new task in Tasks
            // delete old task in Tasks
            
            UserProvider.shared.getTaskTypes { [weak self] (result) in
                switch result {
                case .success(let taskTypes):
                    guard let taskType = taskTypes.randomElement() else { return }
                    let newRef = FirestoreManager.shared.db.collection("Users").document(user.uid).collection("Tasks").document()
                    let newTask = TaskData(documentID: newRef.documentID, restaurantNumber: task.restaurantNumber, people: taskType.people, media: taskType.media, composition: taskType.composition, status: 0, taskID: newRef.documentID)
                    FirestoreManager.shared.addCustomData(docRef: newRef, data: newTask)
                    
                    let oldRef = FirestoreManager.shared.db.collection("Users").document(user.uid).collection("Tasks").document(task.documentID)
                    oldRef.delete()
                    
                    for i in 0..<UserProvider.shared.userTasks.count where UserProvider.shared.userTasks[i].taskID == task.taskID {
                        UserProvider.shared.userTasks[i] = newTask
                    }
                    
                    self?.passTask?(newTask)
                    self?.task = newTask
                    self?.setTaskStatus()
                    self?.taskContentTableView.reloadData()
                case .failure(let error):
                    print("getTaskTypes error: \(error)")
                }
            }
            
        default:
            print("task status error")
            return
        }
        
    }
    
    @IBAction func requestCompanyButtonPressed(_ sender: UIButton) {
        
        guard let task = task, let user = UserProvider.shared.userData else { return }
        
        switch task.status {
        case 0:
            print("status: 0, request company")
        case 1:
            self.task?.status = 0
            for i in 0..<UserProvider.shared.userTasks.count where UserProvider.shared.userTasks[i].taskID == task.taskID {
                UserProvider.shared.userTasks[i].status = 0
            }
            let ref = FirestoreManager.shared.db.collection("Users").document(user.uid).collection("Tasks").document(task.documentID)
            ref.updateData(["status": 0])
            
            setTaskStatus()
        default:
            print("task status error")
            return
        }
    }
    
    func setTaskStatus() {
        guard let task = task else { return }
        switch task.status {
        case 0:
            executeTaskButton.setTitle("上傳任務", for: .normal)
            requestCompanyButton.setTitle("徵求同伴", for: .normal)
            requestCompanyButton.isHidden = false
            showQRCodeButton.isHidden = false
            scanQRCodeButton.isHidden = false
        case 1:
            executeTaskButton.setTitle("確認任務", for: .normal)
            requestCompanyButton.setTitle("重新上傳任務", for: .normal)
        case 2:
            executeTaskButton.setTitle("挑戰新的任務", for: .normal)
            requestCompanyButton.isHidden = true
            showQRCodeButton.isHidden = true
            scanQRCodeButton.isHidden = true
        default:
            print("task status error")
            return
        }
    }
    
    func showExecuteTask() {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "ExecuteTaskViewController") as? ExecuteTaskViewController else { return }
        
        vc.map = map
        vc.restaurant = restaurant
        vc.task = task
        vc.passTask = { [weak self] (task) in
            self?.task = task
            self?.setTaskStatus()
            self?.passTask?(task)
        }
        vc.modalPresentationStyle = .overCurrentContext
        present(vc, animated: true)
    }
    
}

extension TaskContentViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskContentTableViewCell", for: indexPath) as? TaskContentTableViewCell, let restaurant = restaurant, let task = task else { return UITableViewCell() }
        
        switch indexPath.row {
        case 0:
            guard let titleCell = tableView.dequeueReusableCell(withIdentifier: "TaskContentTitleTableViewCell", for: indexPath) as? TaskContentTitleTableViewCell else { return UITableViewCell() }
            titleCell.titleLabel.text = restaurant.name
            return titleCell
        case 1:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Pin_Red)
            cell.contentLabel.text = restaurant.address
        case 2:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Phone_Red)
            cell.contentLabel.text = restaurant.phone
        case 3:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Add_User_Red)
            cell.contentLabel.text = "\(task.people)個人吃飯"
        case 4:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Photo_Camera_Red)
            cell.contentLabel.text = "拍攝照片或影片 x \(task.media)"
        case 5:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Edit_Red)
            cell.contentLabel.text = "寫\(task.composition)字感想"
        case 6:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Key_Red)
            let index = task.taskID.index(task.taskID.startIndex, offsetBy: 4)
            cell.contentLabel.text = "\(task.taskID[...index])（任務代碼前5碼）"
        default:
            return cell
        }
        
        return cell
    }
    
}

extension TaskContentViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row > 0 {
            let spring = UISpringTimingParameters(dampingRatio: 0.6, initialVelocity: CGVector(dx: 1.0, dy: 0.2))
            let animator = UIViewPropertyAnimator(duration: 0.5, timingParameters: spring)
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 100 * 0.6)
            animator.addAnimations { [weak self] in
                cell.alpha = 1
                cell.transform = .identity
                self?.taskContentTableView.layoutIfNeeded()
            }
            animator.startAnimation(afterDelay: 0.05 * Double(indexPath.row))
        }
    }
}
