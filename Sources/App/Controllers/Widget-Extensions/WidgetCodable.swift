//
//  WidgetCodable.swift
//  
//
//  Created by Kevin Bertrand on 05/12/2022.
//

import Foundation

struct Widgets: Codable {
    var yearRevenues: Double
    var monthRevenues: Double
    var estimatesInCreation: Int
    var estimatesInWaiting: Int
    var invoiceInWaiting: Int
    var invoiceUnPaid: Int
}
