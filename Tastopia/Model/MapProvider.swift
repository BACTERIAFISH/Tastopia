//
//  MapProvider.swift
//  Tastopia
//
//  Created by FISH on 2020/2/17.
//  Copyright © 2020 FISH. All rights reserved.
//

import GoogleMaps

class MapProvider {
    
    func createMapRectangle(map: GMSMapView, latitude: CLLocationDegrees, longitude: CLLocationDegrees, height: CLLocationDegrees, width: CLLocationDegrees, fillColor: UIColor = .black) {
        let path = GMSMutablePath()
        
        path.addLatitude(latitude, longitude: longitude)
        path.addLatitude(latitude + height, longitude: longitude)
        path.addLatitude(latitude + height, longitude: longitude + width)
        path.addLatitude(latitude, longitude: longitude + width)
        
        let rectangle = GMSPolygon(path: path)
        rectangle.fillColor = fillColor
        rectangle.map = map
    }
    
    func createMapHollowPolygon(map: GMSMapView, holes coordinates: [CLLocationCoordinate2D]) {
        let polygonPath = GMSMutablePath()
        polygonPath.addLatitude(0, longitude: 0)
        polygonPath.addLatitude(90, longitude: 0)
        polygonPath.addLatitude(90, longitude: 180)
        polygonPath.addLatitude(0, longitude: 180)
        
        var holePaths = [GMSPath]()
        for coordinate in coordinates {
            let latitude = coordinate.latitude + 0.0003
            let longitude = coordinate.longitude
            let path = GMSMutablePath()
            
            for i in stride(from: 0, to: 360, by: 10) {
                
                let radian = Double(i) * Double.pi / 180
                path.addLatitude(latitude + 0.001 * sin(radian), longitude: longitude + 0.001 * cos(radian))
                
            }
            
            holePaths.append(path)
        }
        
        let polygon = GMSPolygon()
        polygon.path = polygonPath
        polygon.holes = holePaths
        polygon.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        polygon.map = map
    }
}
