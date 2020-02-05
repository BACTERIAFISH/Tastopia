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
    
    @IBOutlet weak var taskView: UIView!
    @IBOutlet weak var taskButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var taskViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var taskAddressLabel: UILabel!
    @IBOutlet weak var taskPhoneLabel: UILabel!
    
    var locationManager = CLLocationManager()
    var currentZoom: Float = 18.0
    
    var tasks = [TaskData]()
    var currentTask: TaskData?
    
    override func loadView() {
        super.loadView()
        
        mapView.delegate = self
        let locationAuthStatus = CLLocationManager.authorizationStatus()
        if locationAuthStatus == .authorizedAlways || locationAuthStatus == .authorizedWhenInUse {
            mapView.settings.myLocationButton = true
            mapView.isMyLocationEnabled = true
        }
        mapView.settings.compassButton = true
        
        mapView.isHidden = true
        
        do {
          if let styleURL = Bundle.main.url(forResource: "google-map-style", withExtension: "json") {
            mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
          } else {
            print("Unable to find style.json")
          }
        } catch {
          print("One or more of the map styles failed to load. \(error)")
        }
        //        let marker = GMSMarker()
        //        marker.position = CLLocationCoordinate2D(latitude: 25.042461, longitude: 121.564931)
        //        marker.title = "AppWorks School"
        //        let icon = UIImage.asset(.Icon_64px_Itsukushima)
        //        marker.icon = icon
        //        marker.snippet = "iOS"
        //        marker.map = mapView
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        alertLocationAuth()
        
        taskViewBottomConstraint.constant = -taskView.layer.frame.height - 10
        
        taskView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        taskView.layer.cornerRadius = 16
        taskView.layer.shadowOpacity = 0.3
        taskView.layer.shadowRadius = 3
        taskView.layer.shadowColor = UIColor.SUMI?.cgColor
        
        taskButton.layer.cornerRadius = 5
        recordButton.layer.cornerRadius = 5
        
        NotificationCenter.default.addObserver(self, selector: #selector(getTaskRestaurant), name: NSNotification.Name("taskNumber"), object: nil)
    }
    
    @IBAction func taskButtonPressed(_ sender: UIButton) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "TaskContentViewController") as? TaskContentViewController else { return }
        
        vc.restaurant = currentTask?.restaurant
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
        
    }
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        guard
            let navigationVC = storyboard?.instantiateViewController(withIdentifier: "TaskRecordNavigationController") as? UINavigationController,
            let vc = navigationVC.viewControllers.first as? TaskRecordViewController
        else { return }
        
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "返回", style: .plain, target: self, action: #selector(back))
        vc.titleLabel.text = currentTask?.restaurant.name
//        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
//        let titleLabel = UILabel()
//        titleLabel.font = UIFont(name: "NotoSerifTC-Black", size: 20)
//        titleLabel.text = currentTask?.restaurant.name
//
//        titleView.addSubview(titleLabel)
//
//        titleLabel.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
//        titleLabel.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
//        view.addSubview(titleView)
//
//        vc.navigationItem.titleView = titleView
        //vc.title = currentTask?.restaurant.name
        vc.restaurant = currentTask?.restaurant
        
        navigationVC.modalPresentationStyle = .fullScreen
        present(navigationVC, animated: true)
    }
    
    @IBAction func signOutPress(_ sender: Any) {
        signOut()
    }
    
    func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            print("sign out")
            
            UserDefaults.standard.removeObject(forKey: "firebaseToken")
            UserDefaults.standard.removeObject(forKey: "userData")
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else { return }
            
            appDelegate.window?.rootViewController = loginVC
            
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    func alertLocationAuth() {
        if CLLocationManager.authorizationStatus() == .denied || CLLocationManager.authorizationStatus() == .restricted {
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "定位權限未開啟", message: "為了有更佳的使用者體驗，請至 設定 > 隱私權 > 定位服務，變更權限。", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "ok", style: .default, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @objc func getTaskRestaurant() {
        RestaurantProvider().getTaskRestaurant { [weak self] (result) in
            switch result {
            case .success(let restaurants):
                for restaurant in restaurants {
                    let marker = GMSMarker()
                    marker.position = CLLocationCoordinate2D(latitude: restaurant.position.latitude, longitude: restaurant.position.longitude)
                    marker.title = restaurant.name
                    let icon = UIImage.asset(.Icon_64px_Itsukushima)
                    marker.icon = icon
                    //marker.snippet = "iOS"
                    marker.map = self?.mapView
                    
                    let task = TaskData(marker: marker, restaurant: restaurant)
                    self?.tasks.append(task)
                }
            case .failure(let error):
                print("getTaskRestaurant error: \(error)")
            }
        }
    }
    
    @objc func back() {
        dismiss(animated: true, completion: nil)
    }
}

extension HomeViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        
        // MARK: current zoom
        currentZoom = mapView.camera.zoom
        
        if currentZoom == 17 {
            for task in tasks {
                let icon = UIImage.asset(.Icon_64px_Itsukushima)
                task.marker.icon = icon
            }
        }
        if currentZoom == 16 {
            for task in tasks {
                let icon = UIImage.asset(.Icon_32px_Itsukushima)
                task.marker.icon = icon
            }
        }
        
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        for task in tasks where task.marker == marker {
            currentTask = task
            taskNameLabel.text = task.restaurant.name
            taskAddressLabel.text = task.restaurant.address
            taskPhoneLabel.text = task.restaurant.phone
        }
        
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) { [weak self] in
            self?.taskViewBottomConstraint.constant = 0
            self?.view.layoutIfNeeded()
        }
        animator.startAnimation()
        
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) { [weak self] in
            self?.taskViewBottomConstraint.constant = -(self?.taskView.frame.height ?? 210) - 10
            self?.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        
    }
    
    func mapView(_ mapView: GMSMapView, didCloseInfoWindowOf marker: GMSMarker) {
        
    }
    
}

extension HomeViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last!
        
        let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: currentZoom)
        
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
        
        locationManager.stopUpdatingLocation()
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .restricted, .denied:
            print("Location access was restricted or User denied access to location.")
            let camera = GMSCameraPosition.camera(withLatitude: 25.042529, longitude: 121.564928, zoom: currentZoom)
            mapView.camera = camera
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways, .authorizedWhenInUse:
            print("Location status is OK.")
            mapView.settings.myLocationButton = true
            mapView.isMyLocationEnabled = true
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Location Manager Error: \(error)")
    }
}
