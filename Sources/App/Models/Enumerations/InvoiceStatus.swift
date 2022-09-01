//
//  InvoiceStatus.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Foundation

enum InvoiceStatus: String, Codable {
    case inCreation, sent, payed, overdue
}
