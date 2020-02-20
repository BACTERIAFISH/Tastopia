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
    var markIconSize: MarkerIconSize = .small
    
    var restaurantDatas = [RestaurantData]()
    var currentRestaurantData: RestaurantData?
    var currentUserTask: TaskData?
    
    override func loadView() {
        super.loadView()
        
        TTProgressHUD.shared.hud.dismiss(animated: false)
        
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
        
        // taipei main station
        // (25.047811, 121.517019)
        
        // AppWorks School
        // (25.042451, 121.564920)
        
        let camera = GMSCameraPosition.camera(withLatitude: 25.042451, longitude: 121.564920, zoom: 15)
        mapView.camera = camera
        
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
        taskViewBottomConstraint.constant = -taskView.layer.frame.height
        
        taskView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        taskView.layer.cornerRadius = 16
        taskView.layer.createTTShadow(color: UIColor.SHIRONEZUMI!.cgColor, offset: CGSize(width: 0, height: -2), radius: 3, opacity: 1)
        
        taskButton.layer.cornerRadius = 16
//        taskButton.layer.createTTBorder()
        recordButton.layer.cornerRadius = 16
//        recordButton.layer.createTTBorder()

        NotificationCenter.default.addObserver(self, selector: #selector(userTasksGot), name: NSNotification.Name("userTasks"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getTaskRestaurant), name: NSNotification.Name("addRestaurant"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkLocationAuth()
    }
    
    @IBAction func taskButtonPressed(_ sender: UIButton) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "TaskContentViewController") as? TaskContentViewController else { return }
        
        vc.map = mapView
        vc.restaurant = currentRestaurantData?.restaurant
        vc.task = currentUserTask
        vc.passTaskID = { [weak self] taskID in
            self?.currentUserTask?.taskID = taskID
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
    
    @IBAction func signOutPress(_ sender: Any) {
        signOut()
    }
    
    func signOut() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            print("sign out")
            
            UserDefaults.standard.removeObject(forKey: "uid")
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController else { return }
            
            appDelegate.window?.rootViewController = loginVC
            
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
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
            
            switch result {
            case .success(let restaurants):
                
                var markerPositions = [CLLocationCoordinate2D]()
                
                for restaurant in restaurants {
                    let marker = GMSMarker()
                    marker.position = CLLocationCoordinate2D(latitude: restaurant.position.latitude, longitude: restaurant.position.longitude)
                    
                    markerPositions.append(marker.position)
                    
                    marker.title = restaurant.name
                    let icon = UIImage.asset(.Icon_16px_Dot_Flat)
                    marker.icon = icon
                    //marker.snippet = "iOS"
                    marker.map = self?.mapView
                    
                    let restaurantData = RestaurantData(marker: marker, restaurant: restaurant)
                    self?.restaurantDatas.append(restaurantData)
                    
                }
                
                MapProvider().createMapHollowPolygon(map: strongSelf.mapView, holes: markerPositions)
                
            case .failure(let error):
                print("getTaskRestaurant error: \(error)")
            }
        }
    }
    
    @objc func userTasksGot() {
        taskButton.isEnabled = true
    }

}

extension HomeViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {

        if mapView.camera.zoom >= 17, markIconSize != .large {
            markIconSize = .large
            for restaurantData in restaurantDatas {
                let icon = UIImage.asset(.Icon_64px_Itsukushima)
                restaurantData.marker.icon = icon
            }
        }
        
        if mapView.camera.zoom < 17, mapView.camera.zoom > 15, markIconSize != .medium {
            markIconSize = .medium
            for restaurantData in restaurantDatas {
                let icon = UIImage.asset(.Icon_32px_Itsukushima)
                restaurantData.marker.icon = icon
            }
        }
        
        if mapView.camera.zoom <= 15, markIconSize != .small {
            markIconSize = .small
            for restaurantData in restaurantDatas {
                let icon = UIImage.asset(.Icon_16px_Dot_Flat)
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
        
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) { [weak self] in
            self?.taskViewBottomConstraint.constant = 0
            self?.view.layoutIfNeeded()
        }
        animator.startAnimation()
        
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeIn) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.taskViewBottomConstraint.constant = -strongSelf.taskView.frame.height
            strongSelf.view.layoutIfNeeded()
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
