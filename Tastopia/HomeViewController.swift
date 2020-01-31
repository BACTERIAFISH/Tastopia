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
    
    override func loadView() {
        super.loadView()

        let camera = GMSCameraPosition.camera(withLatitude: 25.042461, longitude: 121.564931, zoom: 18.0)
        mapView.camera = camera
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: 25.042461, longitude: 121.564931)
        marker.title = "AppWorks School"
        marker.snippet = "iOS"
        marker.map = mapView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
