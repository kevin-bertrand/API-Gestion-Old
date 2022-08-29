//
//  InvoiceCodable.swift
//  
//
//  Created by Kevin Bertrand on 29/08/2022.
//

import Foundation
import Vapor
import Fluent

extension Invoice {
    struct Create: Content, Codable {
        let reference: String
        let internalReference: String
        let object: String
        let totalServices: Double
        let totalMaterials: Double
        let total: Double
        let reduction: Double
        let grandTotal: Double
        let status: InvoiceStatus
        let limitPayementDate: Date?
        let clientID: UUID
        let products: [Product.Create]
    }
    
    struct Update: Codable {
        let id: UUID
        let reference: String
        let internalReference: String
        let object: String
        let totalServices: Double
        let totalMaterials: Double
        let total: Double
        let reduction: Double
        let grandTotal: Double
        let status: InvoiceStatus
        let limitPayementDate: Date?
        let products: [Product.Update]
    }
    
    struct Summary: Codable {
        let id: UUID?
        let client: Client.Summary
        let reference: String
        let grandTotal: Double
        let status: InvoiceStatus
        let limitPayementDate: Date
    }
}
