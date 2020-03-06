//
//  restaurantProvider.swift
//  Tastopia
//
//  Created by FISH on 2020/2/2.
//  Copyright © 2020 FISH. All rights reserved.
//

class RestaurantProvider {
    
    func getTaskRestaurant(completion: @escaping (Result<[Restaurant], Error>) -> Void) {
        
        guard let user = UserProvider.shared.userData else { return }
        
        let number = user.taskNumber + 3
        
        let ref = FirestoreReference().restaurantsQuery(isLessThan: number)
        
        FirestoreManager().readData(ref) { (result) in
            switch result {
            case .success(let snapshot):
                FirestoreParser().parseDocuments(decode: snapshot, from: Restaurant.self) { (result) in
                    switch result {
                    case .success(let restaurants):
                        completion(Result.success(restaurants))
                    case .failure(let error):
                        completion(Result.failure(error))
                    }
                }
            case .failure(let error):
                completion(Result.failure(error))
            }
        }
    }
    
}
