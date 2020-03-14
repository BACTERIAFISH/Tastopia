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
            
            TaskProvider.shared.changeTaskID(with: newTaskID, in: task)
            
            self?.task?.taskID = newTaskID
            self?.passTask?(self?.task)
            self?.taskContentTableView.reloadData()
        }
        present(vc, animated: true)
    }
    
    @IBAction func executeTask(_ sender: UIButton) {
        TTSwiftMessages().hideAll()
        
        guard let task = task, let taskStatus = TTTaskStstus(rawValue: task.status) else { return }
        
        switch taskStatus {
        case .start:
            
            if task.people > 1 {
                TTSwiftMessages().question(title: "多人任務", body: "請先同步自己與同伴的任務代碼\n再開始執行任務", leftButtonTitle: "還沒同步", rightButtonTitle: "同步好了", rightHandler: showExecuteTask)
            } else {
                showExecuteTask()
            }
            
        case .submitted:
            
            TTSwiftMessages().wait(title: "確認中")
            
            TaskProvider.shared.checkIsTaskPassed(task: task) { [weak self] (result) in
                switch result {
                case .success(let isPassed):
                    
                    if isPassed {
                        
                        self?.task?.status = 2
                        self?.passTask?(self?.task)
                        
                        UserProvider.shared.checkWhetherAddMoreTask(task: task)
                        
                        TTSwiftMessages().hideAll()
                        TTSwiftMessages().show(color: UIColor.SUMI!, icon: UIImage.asset(.Icon_32px_Success_White)!, title: "任務完成", body: "")
                        
                        self?.setTaskStatus()
                        self?.setStatusImage()
                        
                    } else {
                        
                        TTSwiftMessages().hideAll()
                        TTSwiftMessages().show(color: UIColor.AKABENI!, icon: UIImage.asset(.Icon_32px_Error_White)!, title: "任務未完成", body: "1.上傳的食記數量不足\n2.上傳的食記任務代碼不一致", duration: nil)
                    }
                    
                case .failure(let error):
                    print("checkIsTaskPassed error: \(error)")
                }
            }
            
        case .complete:
            
            TaskProvider.shared.updateTask(task: task) { [weak self] (result) in
                
                switch result {
                case .success(let newTask):
                    
                    self?.passTask?(newTask)
                    self?.task = newTask
                    self?.setTaskStatus()
                    self?.setStatusImage()
                    self?.taskContentTableView.reloadData()
                    
                    TTSwiftMessages().show(color: UIColor.SUMI!, icon: UIImage.asset(.Icon_32px_Success_White)!, title: "任務已更新", body: "")
                    
                case .failure(let error):
                    print("TaskProvider updateTask error: \(error)")
                }
            }
        }
        
    }
    
    @IBAction func requestTaskRestart(_ sender: UIButton) {
        TTSwiftMessages().hideAll()
        
        guard let task = task, let status = TTTaskStstus(rawValue: task.status) else { return }
        
        switch status {
        case .start:
            print("task status: start(0), request company")
        case .submitted:
            TTSwiftMessages().question(title: "確定重新執行任務？", body: nil, leftButtonTitle: "取消", rightButtonTitle: "確定", rightHandler: { [weak self] in
                
                self?.task?.status = TTTaskStstus.start.rawValue
                
                TaskProvider.shared.changeTaskStatus(task: task, status: .start)
                
                self?.passTask?(self?.task)
                
                self?.setTaskStatus()
                
                self?.setStatusImage()
                
                TTSwiftMessages().show(color: UIColor.SUMI!, icon: UIImage.asset(.Icon_32px_Success_White)!, title: "可以再次執行任務", body: "")
            })
        case .complete:
            print("task status: complete(2)")
        }
    }
    
    private func setBeginLayout() {
        
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
    
    private func setTaskStatus() {
        guard let task = task, let status = TTTaskStstus(rawValue: task.status) else { return }
        
        switch status {
        case .start:
            
            executeTaskButton.setTitle("執行任務", for: .normal)
            requestCompanyButton.setTitle("徵求同伴", for: .normal)
            requestCompanyButton.isHidden = true
            scanQRCodeButton.isHidden = false
            
        case .submitted:
            
            executeTaskButton.setTitle("確認任務", for: .normal)
            requestCompanyButton.setTitle("重新執行任務", for: .normal)
            requestCompanyButton.isHidden = false
            scanQRCodeButton.isHidden = true
            
        case .complete:
            
            executeTaskButton.setTitle("挑戰新的任務", for: .normal)
            requestCompanyButton.isHidden = true
            scanQRCodeButton.isHidden = true
        }
    }
    
    private func showExecuteTask() {
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
    
    private func setStatusImage() {
        
        guard let task = task, let status = TTTaskStstus(rawValue: task.status) else { return }
        
        switch status {
        case .start:
            
            statusImageView.isHidden = true
            
        case .submitted:
            
            statusImageView.image = UIImage.asset(.Image_Uploaded)
            animateStatusImage()
            
        case .complete:
            
            statusImageView.image = UIImage.asset(.Image_Completed)
            animateStatusImage()
        }
    }
    
    private func animateStatusImage() {
        
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
    
    private func gameGuide() {
        guard let task = task, let status = TTTaskStstus(rawValue: task.status) else { return }
        switch status {
        case .start:
            
            TTSwiftMessages().info(title: "提示", body: "當任務人數超過1人時\n請先用掃描 QRCode 的方式\n同步自己與同伴的任務代碼\n彼此的任務代碼前5碼都相同後\n再開始執行任務\n", icon: nil, buttonTitle: "確認", backgroundColor: UIColor.SUMI!, foregroundColor: .white, isStatusBarLight: false) {
                
                TTSwiftMessages().info(title: "提示", body: "請在任務地點執行任務\n", icon: nil, buttonTitle: "確認", backgroundColor: UIColor.SUMI!, foregroundColor: .white, isStatusBarLight: false, handler: nil)
            }
            
        case .submitted:
            
            TTSwiftMessages().info(title: "提示", body: "多人任務中\n如果全部人都已上傳食記\n卻無法完成任務\n代表上傳的食記任務代碼不一致\n請重新執行任務\n", icon: nil, buttonTitle: "確認", backgroundColor: UIColor.SUMI!, foregroundColor: .white, isStatusBarLight: false, handler: nil)
            
        case .complete:
            
            TTSwiftMessages().info(title: "提示", body: "完成任務後\n可以繼續挑戰新的任務\n", icon: nil, buttonTitle: "確認", backgroundColor: UIColor.SUMI!, foregroundColor: .white, isStatusBarLight: false, handler: nil)
        }
    }
    
}

extension TaskContentViewController: UITableViewDataSource {
    
    enum TableViewCellCategory: CaseIterable {
        case title
        case address
        case phone
        case people
        case media
        case composition
        case taskID
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TableViewCellCategory.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskContentTableViewCell", for: indexPath) as? TaskContentTableViewCell, let restaurant = restaurant, let task = task else { return UITableViewCell() }
        
        let category = TableViewCellCategory.allCases[indexPath.row]
        
        switch category {
        case .title:
            guard let titleCell = tableView.dequeueReusableCell(withIdentifier: "TaskContentTitleTableViewCell", for: indexPath) as? TaskContentTitleTableViewCell else { return UITableViewCell() }
            titleCell.titleLabel.text = restaurant.name
            return titleCell
        case .address:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Pin_Red)
            cell.contentLabel.text = restaurant.address
        case .phone:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Phone_Red)
            cell.contentLabel.text = restaurant.phone
        case .people:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Add_User_Red)
            cell.contentLabel.text = "\(task.people)個人吃飯（\(task.people)篇食記）"
        case .media:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Photo_Camera_Red)
            cell.contentLabel.text = "拍攝照片或影片 x \(task.media)"
        case .composition:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Edit_Red)
            cell.contentLabel.text = "寫\(task.composition)字感想"
        case .taskID:
            cell.iconImageView.image = UIImage.asset(.Icon_32px_Key_Red)
            let index = task.taskID.index(task.taskID.startIndex, offsetBy: 4)
            cell.contentLabel.text = "\(task.taskID[...index])（任務代碼前5碼）"
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
