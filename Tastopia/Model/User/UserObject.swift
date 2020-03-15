//
//  UserObject.swift
//  Tastopia
//
//  Created by FISH on 2020/3/5.
//  Copyright © 2020 FISH. All rights reserved.
//

struct UserData: Codable {
    let uid: String
    var name: String
    let email: String
    var imagePath: String
    var taskNumber: Int = 0
    var agreeWritings: [String] = []
    var disagreeWritings: [String] = []
    var responseWritings: [String] = []
    var passRestaurant: [Int] = []
    var blackList: [String] = []
}

struct TaskData: Codable {
    let documentID: String
    let restaurantNumber: Int
    let people: Int
    let media: Int
    let composition: Int
    var status: Int // 0, 1, 2
    var taskID: String
}

struct TaskType: Codable {
    let documentID: String
    let people: Int
    let media: Int
    let composition: Int
}
