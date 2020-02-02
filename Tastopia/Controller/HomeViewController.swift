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
    @IBOutlet weak var taskViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var taskAddressLabel: UILabel!
    @IBOutlet weak var taskPhoneLabel: UILabel!
    
    var locationManager = CLLocationManager()
    
    var tasks = [TaskData]()
    
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
        
        taskView.roundCorners(corners: [.topLeft, .topRight], radius: 16)
        taskButton.layer.cornerRadius = 5
        
        NotificationCenter.default.addObserver(self, selector: #selector(getTaskRestaurant), name: NSNotification.Name("taskNumber"), object: nil)
    }
    
    @IBAction func taskButtonPressed(_ sender: UIButton) {
        
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
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let loginVC = self.storyboard?.instantiateViewController(identifier: "LoginViewController") as? LoginViewController else { return }
            
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
}

extension HomeViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        
        for task in tasks where task.marker == marker {
            taskNameLabel.text = task.restaurant.name
            taskAddressLabel.text = task.restaurant.address
            taskPhoneLabel.text = task.restaurant.phone
        }
        
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) { [weak self] in
            self?.taskViewBottomConstraint.constant = 0
            self?.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }
    
    func mapView(_ mapView: GMSMapView, didCloseInfoWindowOf marker: GMSMarker) {
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) { [weak self] in
            self?.taskViewBottomConstraint.constant = -(self?.taskView.frame.height ?? 210)
            self?.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }
    
}

extension HomeViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last!
        
        let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 18.0)
        
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
            let camera = GMSCameraPosition.camera(withLatitude: 25.042529, longitude: 121.564928, zoom: 17.0)
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
