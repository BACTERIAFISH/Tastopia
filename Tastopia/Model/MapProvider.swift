//
//  MapProvider.swift
//  Tastopia
//
//  Created by FISH on 2020/2/17.
//  Copyright © 2020 FISH. All rights reserved.
//

import GoogleMaps

class MapProvider {
    
    func setMapStyle(map: GMSMapView) {
        do {
          if let styleURL = Bundle.main.url(forResource: "google-map-style", withExtension: "json") {
            map.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
          } else {
            print("Unable to find google-map-style.json")
          }
        } catch {
          print("The map styles failed to load. \(error)")
        }
    }
    
    func createWorldMapShadow(map: GMSMapView) {
        createMapRectangle(map: map, latitude: 0, longitude: 0, height: 90, width: -180, fillColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.6))
        createMapRectangle(map: map, latitude: 0, longitude: 0, height: -89, width: 180, fillColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.6))
        createMapRectangle(map: map, latitude: 0, longitude: 0, height: -89, width: -180, fillColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.6))
    }
    
    private func createMapRectangle(map: GMSMapView, latitude: CLLocationDegrees, longitude: CLLocationDegrees, height: CLLocationDegrees, width: CLLocationDegrees, fillColor: UIColor = .black) {
        let path = GMSMutablePath()
        
        path.addLatitude(latitude, longitude: longitude)
        path.addLatitude(latitude + height, longitude: longitude)
        path.addLatitude(latitude + height, longitude: longitude + width)
        path.addLatitude(latitude, longitude: longitude + width)
        
        let rectangle = GMSPolygon(path: path)
        rectangle.fillColor = fillColor
        rectangle.map = map
    }
    
    func createMapHollowPolygon(map: GMSMapView, restaurants: [Restaurant]) {
        guard let passRestaurants = UserProvider.shared.userData?.passRestaurant else { return }
        
        let polygonPath = GMSMutablePath()
        polygonPath.addLatitude(0, longitude: 0)
        polygonPath.addLatitude(90, longitude: 0)
        polygonPath.addLatitude(90, longitude: 180)
        polygonPath.addLatitude(0, longitude: 180)
        
        var holePaths = [GMSPath]()
        for restaurant in restaurants {
            let path = GMSMutablePath()
            let latitude = restaurant.position.latitude + 0.0003
            let longitude = restaurant.position.longitude
            var radius = 0.001
            if passRestaurants.contains(restaurant.number) {
                radius = 0.0014
            }
            
            for index in stride(from: 0, to: 360, by: 10) {
                
                let radian = Double(index) * Double.pi / 180
                path.addLatitude(latitude + radius * sin(radian), longitude: longitude + radius * cos(radian))
                
            }
            
            holePaths.append(path)
        }
        
        let polygon = GMSPolygon()
        polygon.path = polygonPath
        polygon.holes = holePaths
        polygon.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        polygon.zIndex = 100
        polygon.map = map
    }
    
}
