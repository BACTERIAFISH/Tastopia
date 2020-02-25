//
//  HomeViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/1/30.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit
import Firebase
import GoogleMaps

class HomeViewController: UIViewController {
    
    @IBOutlet weak var mapView: GMSMapView!

    @IBOutlet weak var UserButton: UIButton!
    
    @IBOutlet weak var taskView: UIView!
    @IBOutlet weak var taskButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var taskViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var taskAddressLabel: UILabel!
    @IBOutlet weak var taskPhoneLabel: UILabel!
    
    @IBOutlet weak var shadowTopView: UIView!
    @IBOutlet weak var shadowContainView: UIView!
    @IBOutlet weak var shadowLeftView: UIView!
    @IBOutlet weak var shadowRightView: UIView!
    
    var locationManager = CLLocationManager()
    var markIconSize: MarkerIconSize = .small
    
    var restaurantDatas = [RestaurantData]()
    var currentRestaurantData: RestaurantData?
    var currentUserTask: TaskData?
    
    override func loadView() {
        super.loadView()
        
        TTSwiftMessages().hideAll()
        
        mapView.delegate = self
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        mapView.settings.compassButton = true
        
        do {
          if let styleURL = Bundle.main.url(forResource: "google-map-style", withExtension: "json") {
            mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
          } else {
            print("Unable to find style.json")
          }
        } catch {
          print("One or more of the map styles failed to load. \(error)")
        }
        
        getTaskRestaurant()
        
        MapProvider().createMapRectangle(map: mapView, latitude: 0, longitude: 0, height: 90, width: -180, fillColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.6))
        MapProvider().createMapRectangle(map: mapView, latitude: 0, longitude: 0, height: -89, width: 180, fillColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.6))
        MapProvider().createMapRectangle(map: mapView, latitude: 0, longitude: 0, height: -89, width: -180, fillColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.6))

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        
        view.layoutIfNeeded()
        UserButton.layer.cornerRadius = 30
        taskViewBottomConstraint.constant = taskView.layer.frame.height
        
        taskView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        taskView.layer.cornerRadius = 16
        taskView.layer.createTTShadow(color: UIColor.SHIRONEZUMI!.cgColor, offset: CGSize(width: 0, height: -2), radius: 3, opacity: 1)
        
        taskButton.layer.cornerRadius = 16
        recordButton.layer.cornerRadius = 16

        NotificationCenter.default.addObserver(self, selector: #selector(userTasksGot), name: NSNotification.Name("userTasks"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getTaskRestaurant), name: NSNotification.Name("addRestaurant"), object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkLocationAuth()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserDefaults.standard.integer(forKey: "userStatus") == 0 {
            gameGuide()
        }
        
    }
    
    @IBAction func userButtonPressed(_ sender: UIButton) {
        
        guard let profileVC = storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController else { return }
        
        profileVC.user = UserProvider.shared.userData

        profileVC.showGameGuide = { [weak self] in
            guard let strongSelf = self else { return }
            if !strongSelf.taskView.isHidden {
                let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) {
                    strongSelf.taskViewBottomConstraint.constant = strongSelf.taskView.frame.height
                    strongSelf.view.layoutIfNeeded()
                }
                animator.addCompletion { _ in
                    strongSelf.taskView.isHidden = true
                    strongSelf.gameGuide()
                }
                animator.startAnimation()
            } else {
                strongSelf.gameGuide()
            }
        }
        
        profileVC.modalPresentationStyle = .overFullScreen
        present(profileVC, animated: false)

    }
    
    @IBAction func taskButtonPressed(_ sender: UIButton) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "TaskContentViewController") as? TaskContentViewController else { return }
        
        vc.map = mapView
        vc.restaurant = currentRestaurantData?.restaurant
        vc.task = currentUserTask
        vc.passTask = { [weak self] task in
            self?.currentUserTask = task
        }
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
        
    }
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        guard
            let navigationVC = storyboard?.instantiateViewController(withIdentifier: "TaskRecordNavigationController") as? UINavigationController,
            let vc = navigationVC.viewControllers.first as? TaskRecordViewController
        else { return }

        vc.titleLabel.text = currentRestaurantData?.restaurant.name

        vc.restaurant = currentRestaurantData?.restaurant
        
        navigationVC.modalPresentationStyle = .fullScreen
        present(navigationVC, animated: true)
    }
    
    func checkLocationAuth() {
        let locationAuthStatus = CLLocationManager.authorizationStatus()
        switch locationAuthStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.isHidden = false
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            mapView.isHidden = true
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "定位權限未開啟", message: "為了進行遊戲，請至 設定 > 隱私權 > 定位服務，變更權限。", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "ok", style: .default, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
        @unknown default:
            print("switch CLLocationManager.authorizationStatus() error")
        }

    }
    
    @objc func getTaskRestaurant() {
        RestaurantProvider().getTaskRestaurant { [weak self] (result) in
            guard let strongSelf = self else { return }
            guard let passRestaurant = UserProvider.shared.userData?.passRestaurant else { return }
            
            switch result {
            case .success(let restaurants):
                
                for restaurant in restaurants {
                    let marker = GMSMarker()
                    marker.position = CLLocationCoordinate2D(latitude: restaurant.position.latitude, longitude: restaurant.position.longitude)
                    
                    marker.title = restaurant.name
                    
                    var icon = UIImage.asset(.Icon_16px_Dot_Flat)
                    if passRestaurant.contains(restaurant.number) {
                        icon = UIImage.asset(.Icon_16px_Dot_Flat_Black)
                    }
                    marker.icon = icon
                    //marker.snippet = "iOS"
                    marker.map = self?.mapView
                    
                    let restaurantData = RestaurantData(marker: marker, restaurant: restaurant)
                    self?.restaurantDatas.append(restaurantData)
                    
                }
                
                MapProvider().createMapHollowPolygon(map: strongSelf.mapView, restaurants: restaurants)
                
            case .failure(let error):
                print("getTaskRestaurant error: \(error)")
            }
        }
    }
    
    @objc func userTasksGot() {
        taskButton.isEnabled = true
    }

    func gameGuide() {
                
        TTSwiftMessages().info(title: "歡迎來到 Tastopia", body: "這裡有各式各樣的美食任務\n等著你去探索、品嚐、紀錄\n來看看目前有哪些美食任務吧\n", icon: nil, buttonTitle: "下一步", handler: { [weak self] in
            
            self?.mapView.animate(to: GMSCameraPosition(latitude: 25.042213, longitude: 121.563074, zoom: 15))
            
            TTSwiftMessages().info(title: "尋找任務", body: "滑動地圖的時候\n你會發現地圖上有幾處被照亮的地方\n那就是任務所在的地點\n", icon: nil, buttonTitle: "下一步", handler: {
                
                self?.mapView.animate(toZoom: 17)
                
                TTSwiftMessages().info(title: "尋找任務", body: "放大地圖後\n可以更清楚的看到任務地點\n", icon: nil, buttonTitle: "下一步", handler: {
                    
                    // MARK: 可加點擊動畫
                    self?.taskView.isHidden = false
                    let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) {
                        self?.taskViewBottomConstraint.constant = 0
                        self?.view.layoutIfNeeded()
                    }
                    animator.addCompletion { _ in
                        
                        self?.shadowTopView.isHidden = false
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            
                            TTSwiftMessages().info(title: "選擇任務", body: "點擊地圖上的任務圖案\n會彈出任務視窗\n顯示任務的基本訊息\n", icon: nil, buttonTitle: "下一步", handler: {
                                
                                self?.shadowContainView.isHidden = false
                                self?.shadowLeftView.isHidden = true

                                TTSwiftMessages().info(title: "任務紀錄", body: "顯示之前的任務紀錄\n也可以查看別人的紀錄\n", icon: nil, buttonTitle: "下一步", handler: {
                                    
                                    self?.shadowLeftView.isHidden = false
                                    self?.shadowRightView.isHidden = true
                                    
                                    TTSwiftMessages().info(title: "查看任務", body: "顯示詳細的任務內容\n也是執行任務的地方\n", icon: nil, buttonTitle: "下一步", handler: {
                                        
                                        self?.shadowRightView.isHidden = false
                                        
                                        TTSwiftMessages().info(title: "準備好了嗎？", body: "按下開始進入 Tastopia !!\n", icon: nil, buttonTitle: "開始", handler: {
                                            
                                            UserDefaults.standard.set(1, forKey: "userStatus")
                                            
                                            self?.shadowTopView.isHidden = true
                                            self?.shadowContainView.isHidden = true
                                            
                                            let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) {
                                                guard let strongSelf = self else { return }
                                                strongSelf.taskViewBottomConstraint.constant = strongSelf.taskView.frame.height
                                                strongSelf.view.layoutIfNeeded()
                                            }
                                            animator.addCompletion { _ in
                                                self?.taskView.isHidden = true
                                                
                                                guard let location = self?.mapView.myLocation?.coordinate else { return }
                                                self?.mapView.animate(to: GMSCameraPosition(target: location, zoom: 15))
                                                
                                            }
                                            animator.startAnimation()
                                        })
                                    })
                                    
                                })
                            })
                        }
                    }
                    animator.startAnimation()
                })
            })
        })
    }
}

extension HomeViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        guard let passRestaurant = UserProvider.shared.userData?.passRestaurant else { return }
        
        if mapView.camera.zoom >= 19, markIconSize != .large {
            markIconSize = .large
            for restaurantData in restaurantDatas {
                var icon = UIImage.asset(.Icon_128px_Food_Location)
                if passRestaurant.contains(restaurantData.restaurant.number) {
                    icon = UIImage.asset(.Icon_128px_Food_Location_Black)
                }
                restaurantData.marker.icon = icon
            }
        }
        
        if mapView.camera.zoom < 19, mapView.camera.zoom > 15, markIconSize != .medium {
            markIconSize = .medium
            for restaurantData in restaurantDatas {
                var icon = UIImage.asset(.Icon_64px_Food_Location)
                if passRestaurant.contains(restaurantData.restaurant.number) {
                    icon = UIImage.asset(.Icon_64px_Food_Location_Black)
                }
                restaurantData.marker.icon = icon
            }
        }
        
        if mapView.camera.zoom <= 15, markIconSize != .small {
            markIconSize = .small
            for restaurantData in restaurantDatas {
                var icon = UIImage.asset(.Icon_16px_Dot_Flat)
                if passRestaurant.contains(restaurantData.restaurant.number) {
                    icon = UIImage.asset(.Icon_16px_Dot_Flat_Black)
                }
                restaurantData.marker.icon = icon
            }
        }
        
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        for restaurantData in restaurantDatas where restaurantData.marker == marker {
            currentRestaurantData = restaurantData
            for userTask in UserProvider.shared.userTasks where userTask.restaurantNumber == restaurantData.restaurant.number {
                currentUserTask = userTask
            }
            taskNameLabel.text = restaurantData.restaurant.name
            taskAddressLabel.text = restaurantData.restaurant.address
            taskPhoneLabel.text = restaurantData.restaurant.phone
        }
        if taskView.isHidden {
            taskView.isHidden = false
            let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) { [weak self] in
                self?.taskViewBottomConstraint.constant = 0
                self?.view.layoutIfNeeded()
            }
            animator.startAnimation()
        }
        
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        if !taskView.isHidden {
            let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.taskViewBottomConstraint.constant = strongSelf.taskView.frame.height
                strongSelf.view.layoutIfNeeded()
            }
            animator.addCompletion { [weak self] _ in
                self?.taskView.isHidden = true
            }
            animator.startAnimation()
        }
        
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        
    }
    
    func mapView(_ mapView: GMSMapView, didCloseInfoWindowOf marker: GMSMarker) {
        
    }
    
}

extension HomeViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // taipei main station
        // (25.047811, 121.517019)
        
        // AppWorks School
        // (25.042451, 121.564920)
        
        let location = locations.last!
        
        let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 15)
        
        mapView.camera = camera
        
        locationManager.stopUpdatingLocation()
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuth()
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Location Manager Error: \(error)")
    }
    
}

enum MarkerIconSize {
    case large
    case medium
    case small
}
