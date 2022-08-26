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
}
