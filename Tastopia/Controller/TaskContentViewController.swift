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
import SwiftMessages

class TaskContentViewController: UIViewController {
    
    @IBOutlet weak var taskContentTableView: UITableView!
    @IBOutlet weak var statusImageView: UIImageView!
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
        
        setBeginLayout()
        
        setTaskStatus()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setStatusImage()
    }
    
    @IBAction func back(_ sender: Any) {
        
        TTSwiftMessages().hideAll()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func info(_ sender: Any) {
        
        TTSwiftMessages().hideAll()
        gameGuide()
    }
    
    @IBAction func scanQRCode() {
        
        TTSwiftMessages().hideAll()
        
        guard let vc = storyboard?.instantiateViewController(withIdentifier: TTConstant.ViewControllerID.qrCodeScanViewController) as? QRCodeScanViewController else { return }
        
        vc.modalPresentationStyle = .overFullScreen
        vc.task = task
        vc.passTaskID = { [weak self] newTaskID in
            
            guard let task = self?.task else { return }
            
            UserProvider.shared.changeTaskID(with: newTaskID, in: task)

            self?.task?.taskID = newTaskID
            self?.passTask?(self?.task)
            self?.taskContentTableView.reloadData()
        }
        present(vc, animated: true)
    }
    
    @IBAction func executeTask(_ sender: UIButton) {
        TTSwiftMessages().hideAll()
        
        guard let task = task, let user = UserProvider.shared.userData else { return }
        switch task.status {
        case 0:
            
            if task.people > 1 {
                TTSwiftMessages().question(title: "多人任務", body: "請先同步自己與同伴的任務代碼\n再開始執行任務", leftButtonTitle: "還沒同步", rightButtonTitle: "同步好了", leftHandler: nil, rightHandler: showExecuteTask)
            } else {
                showExecuteTask()
            }
            
        case 1:
            // 確認任務
            // check writings where restaurant, taskID, date >= task.people
            TTSwiftMessages().wait(title: "確認中")
            WritingProvider().checkTaskWritings(task: task) { [weak self] (result) in
//                guard let strongSelf = self else { return }
                switch result {
                case .success(let pass):
                    if pass {
                        self?.task?.status = 2
                        for index in 0..<UserProvider.shared.userTasks.count where UserProvider.shared.userTasks[index].taskID == task.taskID {
                            UserProvider.shared.userTasks[index].status = 2
                        }
                        let ref = FirestoreManager().db.collection("Users").document(user.uid).collection("Tasks").document(task.documentID)
                        ref.updateData(["status": 2])
                        self?.passTask?(self?.task)
                                
                        // 檢查是否有存進 user passRestaurant array
                        // 如果沒有，存user passRestaurant array
                        // taskNumber += 1
                        // add task in Tasks
                        if !user.passRestaurant.contains(task.restaurantNumber) {
                            UserProvider.shared.userData?.passRestaurant.append(task.restaurantNumber)
                            UserProvider.shared.userData?.taskNumber += 1
                            let ref = FirestoreManager().db.collection("Users").document(user.uid)
                            FirestoreManager().addData(docRef: ref, data: [
                                "taskNumber": user.taskNumber + 1,
                                "passRestaurant": FieldValue.arrayUnion([task.restaurantNumber])
                            ])
                            
                            UserProvider.shared.getTaskTypes { (result) in
                                switch result {
                                case .success(let taskTypes):
                                    guard let taskType = taskTypes.randomElement() else { return }
                                    let ref = FirestoreManager().db.collection("Users").document(user.uid).collection("Tasks").document()
                                    let newTask = TaskData(documentID: ref.documentID, restaurantNumber: user.taskNumber + 3, people: taskType.people, media: taskType.media, composition: taskType.composition, status: 0, taskID: ref.documentID)
                                    FirestoreManager().addCustomData(docRef: ref, data: newTask)
                                    
                                    UserProvider.shared.userTasks.append(newTask)
                                    
                                    NotificationCenter.default.post(name: NSNotification.Name("addRestaurant"), object: nil)
                                case .failure(let error):
                                    print("getTaskTypes error: \(error)")
                                }
                            }
                        }
                        
                        TTSwiftMessages().hideAll()
                        TTSwiftMessages().show(color: UIColor.SUMI!, icon: UIImage.asset(.Icon_32px_Success_White)!, title: "任務完成", body: "")
                        
                        self?.setTaskStatus()
                        self?.setStatusImage()
                        
                    } else {
                        // show mission fail
                        TTSwiftMessages().hideAll()
                        TTSwiftMessages().show(color: UIColor.AKABENI!, icon: UIImage.asset(.Icon_32px_Error_White)!, title: "任務未完成", body: "1.上傳的食記數量不足\n2.上傳的食記任務代碼不一致", duration: nil)
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
                    let newRef = FirestoreManager().db.collection("Users").document(user.uid).collection("Tasks").document()
                    let newTask = TaskData(documentID: newRef.documentID, restaurantNumber: task.restaurantNumber, people: taskType.people, media: taskType.media, composition: taskType.composition, status: 0, taskID: newRef.documentID)
                    FirestoreManager().addCustomData(docRef: newRef, data: newTask)
                    
                    let oldRef = FirestoreManager().db.collection("Users").document(user.uid).collection("Tasks").document(task.documentID)
                    oldRef.delete()
                    
                    for index in 0..<UserProvider.shared.userTasks.count where UserProvider.shared.userTasks[index].taskID == task.taskID {
                        UserProvider.shared.userTasks[index] = newTask
                    }
                    
                    self?.passTask?(newTask)
                    self?.task = newTask
                    self?.setTaskStatus()
                    self?.setStatusImage()
                    self?.taskContentTableView.reloadData()
                    
                    TTSwiftMessages().show(color: UIColor.SUMI!, icon: UIImage.asset(.Icon_32px_Success_White)!, title: "任務已更新", body: "")
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
        TTSwiftMessages().hideAll()
        
        guard let task = task, let user = UserProvider.shared.userData else { return }
        
        switch task.status {
        case 0:
            print("status: 0, request company")
        case 1:
            TTSwiftMessages().question(title: "確定重新執行任務？", body: nil, leftButtonTitle: "取消", rightButtonTitle: "確定", leftHandler: nil, rightHandler: { [weak self] in
                self?.task?.status = 0
                for index in 0..<UserProvider.shared.userTasks.count where UserProvider.shared.userTasks[index].taskID == task.taskID {
                    UserProvider.shared.userTasks[index].status = 0
                }
                let ref = FirestoreManager().db.collection("Users").document(user.uid).collection("Tasks").document(task.documentID)
                ref.updateData(["status": 0])
                
                self?.passTask?(self?.task)
                
                self?.setTaskStatus()
                self?.setStatusImage()
                TTSwiftMessages().show(color: UIColor.SUMI!, icon: UIImage.asset(.Icon_32px_Success_White)!, title: "可以再次執行任務", body: "")
            })
        default:
            print("task status error")
            return
        }
    }
    
    func setBeginLayout() {
        
        taskContentTableView.layer.cornerRadius = 16
        taskContentTableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        taskContentTableView.layer.createTTBorder()
        
        scanQRCodeButton.layer.cornerRadius = 16
        requestCompanyButton.layer.cornerRadius = 16
        executeTaskButton.layer.cornerRadius = 16
        
        statusImageView.layer.cornerRadius = 16
        statusImageView.layer.borderColor = UIColor.AKABENI!.cgColor
        statusImageView.layer.borderWidth = 5

    }
    
    func setTaskStatus() {
        guard let task = task else { return }
        switch task.status {
        case 0:
            executeTaskButton.setTitle("執行任務", for: .normal)
            requestCompanyButton.setTitle("徵求同伴", for: .normal)
            requestCompanyButton.isHidden = true
            scanQRCodeButton.isHidden = false
        case 1:
            executeTaskButton.setTitle("確認任務", for: .normal)
            requestCompanyButton.setTitle("重新執行任務", for: .normal)
            requestCompanyButton.isHidden = false
            scanQRCodeButton.isHidden = true
        case 2:
            executeTaskButton.setTitle("挑戰新的任務", for: .normal)
            requestCompanyButton.isHidden = true
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
        vc.setStatusImage = setStatusImage
        vc.modalPresentationStyle = .overCurrentContext
        present(vc, animated: true)
    }
    
    func setStatusImage() {
        guard let task = task else { return }
        switch task.status {
        case 0:
            statusImageView.isHidden = true
        case 1:
            statusImageView.image = UIImage.asset(.Image_Uploaded)
            animateStatusImage()
        case 2:
            statusImageView.image = UIImage.asset(.Image_Completed)
            animateStatusImage()
        default:
            print("task status error")
            return
        }
    }
    
    func animateStatusImage() {
        
        statusImageView.isHidden = true
        statusImageView.alpha = 0.5
        statusImageView.transform = CGAffineTransform(scaleX: 2, y: 2).rotated(by: CGFloat.pi / 180 * 30)
        statusImageView.layoutIfNeeded()
        
        let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeIn) { [weak self] in
            self?.statusImageView.isHidden = false
            self?.statusImageView.alpha = 1
            self?.statusImageView.transform = CGAffineTransform(scaleX: 1, y: 1).rotated(by: CGFloat.pi / 180 * 15)
            self?.statusImageView.layoutIfNeeded()
        }
        animator.startAnimation()
    }
    
    func gameGuide() {
        guard let task = task else { return }
        switch task.status {
        case 0:
            TTSwiftMessages().info(title: "提示", body: "當任務人數超過1人時\n請先用掃描 QRCode 的方式\n同步自己與同伴的任務代碼\n彼此的任務代碼前5碼都相同後\n再開始執行任務\n", icon: nil, buttonTitle: "確認", backgroundColor: UIColor.SUMI!, foregroundColor: .white, isStatusBarLight: false) {
                
                TTSwiftMessages().info(title: "提示", body: "請在任務地點執行任務\n", icon: nil, buttonTitle: "確認", backgroundColor: UIColor.SUMI!, foregroundColor: .white, isStatusBarLight: false) {
                    
                }
            }
        case 1:
            TTSwiftMessages().info(title: "提示", body: "多人任務中\n如果全部人都已上傳食記\n卻無法完成任務\n代表上傳的食記任務代碼不一致\n請重新執行任務\n", icon: nil, buttonTitle: "確認", backgroundColor: UIColor.SUMI!, foregroundColor: .white, isStatusBarLight: false) {
                
            }
        case 2:
            TTSwiftMessages().info(title: "提示", body: "完成任務後\n可以繼續挑戰新的任務\n", icon: nil, buttonTitle: "確認", backgroundColor: UIColor.SUMI!, foregroundColor: .white, isStatusBarLight: false) {
                
            }
        default:
            print("task status error")
            return
        }
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
            cell.contentLabel.text = "\(task.people)個人吃飯（\(task.people)篇食記）"
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
