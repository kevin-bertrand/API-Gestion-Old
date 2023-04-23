//
//  Date.swift
//  
//
//  Created by Kevin Bertrand on 11/09/2022.
//

import Foundation

extension Date {
    /// Get the date at the format dd/MM/yyyy
    var dateOnly: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: self)
    }
}
