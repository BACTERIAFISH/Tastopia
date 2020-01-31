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
    
    override func loadView() {
        super.loadView()
        
        mapView.delegate = self
        mapView.settings.myLocationButton = true

        let camera = GMSCameraPosition.camera(withLatitude: 25.042461, longitude: 121.564931, zoom: 18.0)
        mapView.camera = camera
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: 25.042461, longitude: 121.564931)
        marker.title = "AppWorks School"
        let icon = UIImage.asset(.Icon_64px_Itsukushima)
        marker.icon = icon
        //marker.snippet = "iOS"
        marker.map = mapView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        taskView.roundCorners(corners: [.topLeft, .topRight], radius: 16)
        taskButton.layer.cornerRadius = 5
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
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let loginVC = self.storyboard?.instantiateViewController(identifier: "LoginViewController") as? LoginViewController else { return }
            
            appDelegate.window?.rootViewController = loginVC
            
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}

extension HomeViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        
        let animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeIn) { [weak self] in
            self?.taskViewBottomConstraint.constant = 0
            self?.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }
    
    func mapView(_ mapView: GMSMapView, didCloseInfoWindowOf marker: GMSMarker) {
        let animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeIn) { [weak self] in
            self?.taskViewBottomConstraint.constant = -(self?.taskView.frame.height ?? 210)
            self?.view.layoutIfNeeded()
        }
        animator.startAnimation()
    }
    
    func mapView(_ mapView: GMSMapView, didTapMyLocation location: CLLocationCoordinate2D) {
        print("222")
    }
}
