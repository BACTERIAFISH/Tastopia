//
//  DateFormatter+Extension.swift
//  Tastopia
//
//  Created by FISH on 2020/3/17.
//  Copyright © 2020 FISH. All rights reserved.
//

import Foundation

extension DateFormatter {
    
    static func createTTDate(date: Date, format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
}
