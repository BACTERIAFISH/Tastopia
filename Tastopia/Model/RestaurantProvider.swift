//
//  restaurantProvider.swift
//  Tastopia
//
//  Created by FISH on 2020/2/2.
//  Copyright © 2020 FISH. All rights reserved.
//

import FirebaseFirestore
import GoogleMaps

class RestaurantProvider {
    
    func getTaskRestaurant(completion: @escaping (Result<[Restaurant], Error>) -> Void) {
        
        guard let taskNumber = UserProvider.shared.taskNumber else { return }
        
        let number = taskNumber + 3
        
        FirestoreManager.shared.db.collection("Restaurants")
        .whereField("number", isLessThan: number)
        .getDocuments { (query, error) in
            if let error = error {
                completion(Result.failure(error))
            } else {
                var restaurants = [Restaurant]()
                for doc in query!.documents {
                    
                    let result = Result {
                        try doc.data(as: Restaurant.self)
                    }
                    
                    switch result {
                    case .success(let restaurant):
                        if let restaurant = restaurant {
                            restaurants.append(restaurant)
                        }
                    case .failure(let error):
                        print("getTaskRestaurant decode error: \(error)")
                    }
                }
                completion(Result.success(restaurants))
            }
        }
    }
}

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
