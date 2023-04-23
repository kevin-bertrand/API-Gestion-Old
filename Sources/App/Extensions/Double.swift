//
//  Double.swift
//  
//
//  Created by Kevin Bertrand on 26/08/2022.
//

import Foundation

extension Double {
    var toDate: Date? {
        return Date(timeIntervalSince1970: self)
    }
    
    /// Truncate a double to a two digits number
    var twoDigitPrecision: String {
        return String(format: "%.2f", self)
    }
}
