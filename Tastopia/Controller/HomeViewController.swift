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
    var isLargeIcon = false
    
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
//        guard let latitudeDegrees = CLLocationDegrees(exactly: 25.047811), let longitudeDegrees = CLLocationDegrees(exactly: 121.517019) else { return }
        
        // AppWorks School
        guard let latitudeDegrees = CLLocationDegrees(exactly: 25.042451), let longitudeDegrees = CLLocationDegrees(exactly: 121.564920) else { return }
        
        let camera = GMSCameraPosition.camera(withLatitude: latitudeDegrees, longitude: longitudeDegrees, zoom: 14)
        mapView.camera = camera
        
        getTaskRestaurant()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        
        taskViewBottomConstraint.constant = -taskView.layer.frame.height - 10
        
        taskView.layer.createTTShadow(color: UIColor.SUMI!.cgColor, offset: CGSize(width: 0, height: -3), radius: 3, opacity: 0.3)
        
        taskButton.layer.cornerRadius = 5
        recordButton.layer.cornerRadius = 5

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
            switch result {
            case .success(let restaurants):
                for restaurant in restaurants {
                    let marker = GMSMarker()
                    marker.position = CLLocationCoordinate2D(latitude: restaurant.position.latitude, longitude: restaurant.position.longitude)
                    marker.title = restaurant.name
                    let icon = UIImage.asset(.Icon_32px_Itsukushima)
                    marker.icon = icon
                    //marker.snippet = "iOS"
                    marker.map = self?.mapView
                    
                    let restaurantData = RestaurantData(marker: marker, restaurant: restaurant)
                    self?.restaurantDatas.append(restaurantData)
                    
                }
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

        if mapView.camera.zoom >= 17, !isLargeIcon {
            isLargeIcon = true
            for restaurantData in restaurantDatas {
                let icon = UIImage.asset(.Icon_64px_Itsukushima)
                restaurantData.marker.icon = icon
            }
        }
        
        if mapView.camera.zoom < 17, isLargeIcon {
            isLargeIcon = false
            for restaurantData in restaurantDatas {
                let icon = UIImage.asset(.Icon_32px_Itsukushima)
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
        
        let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 14)
        
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
