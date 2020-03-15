//
//  RestaurantObject.swift
//  Tastopia
//
//  Created by FISH on 2020/3/6.
//  Copyright © 2020 FISH. All rights reserved.
//

import FirebaseFirestore
import GoogleMaps

struct Restaurant: Codable {
    let number: Int
    let name: String
    let address: String
    let phone: String
    let position: GeoPoint
}

struct RestaurantData {
    let marker: GMSMarker
    let restaurant: Restaurant
}
