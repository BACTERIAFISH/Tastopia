//
//  WritingObject.swift
//  Tastopia
//
//  Created by FISH on 2020/3/16.
//  Copyright © 2020 FISH. All rights reserved.
//

import Foundation
import UIKit

struct WritingData: Codable {
    let documentID: String
    let date: Date
    let number: Int
    let uid: String
    let userName: String
    let userImagePath: String
    var composition: String
    var medias: [String]
    var mediaTypes: [String]
    var agree: Int
    var disagree: Int
    var responseNumber: Int
    var taskID: String
}

struct ResponseData: Codable {
    let documentID: String
    let date: Date
    let uid: String
    let userName: String
    let userImagePath: String
    let response: String
}

struct TTMediaData {
    var mediaType: String
    var urlString: String = ""
    var url: URL?
    var image: UIImage?
}
