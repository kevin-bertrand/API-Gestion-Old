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
        let totalDivers: Double
        let total: Double
        let grandTotal: Double
        let status: InvoiceStatus
        let limitPayementDate: Date?
        let clientID: UUID
        let paymentID: UUID?
        let comment: String?
        let products: [Product.Create]
        let limitMaximumInterests: Date?
        let maxInterests: Double?
    }
    
    struct Update: Codable {
        let id: UUID
        let reference: String
        let internalReference: String
        let object: String
        let totalServices: Double
        let totalMaterials: Double
        let totalDivers: Double
        let total: Double
        let grandTotal: Double
        let status: InvoiceStatus
        let limitPayementDate: Date?
        let facturationDate: Date
        let creationDate: Date?
        let paymentID: UUID?
        let comment: String?
        let products: [Product.Update]
        let limitMaximumInterests: Date?
        let maxInterests: Double?
    }
    
    struct Summary: Codable {
        let id: UUID?
        let client: Client.Summary
        let reference: String
        let grandTotal: Double
        let status: InvoiceStatus
        let limitPayementDate: Date
        let isArchive: Bool
    }
    
    struct Informations: Codable {
        let id: UUID
        let reference: String
        let internalReference: String
        let object: String
        let totalServices: Double
        let totalMaterials: Double
        let totalDivers: Double
        let total: Double
        let grandTotal: Double
        let status: InvoiceStatus
        let limitPayementDate: Date
        let facturationDate: Date
        let delayDays: Int
        let totalDelay: Double
        let creationDate: Date?
        let client: Client.Informations
        let products: [Product.Informations]
        let payment: PayementMethod?
        let isArchive: Bool
        let comment: String?
        let limitMaximumInterests: Date?
        let maxInterests: Double?
    }
    
    struct PDF: Codable {
        let creationDate: String
        let reference: String
        let clientName: String
        let clientAddress: String
        let clientCity: String
        let clientCountry: String
        let internalReference: String
        let object: String
        let paymentTitle: String
        let iban: String
        let bic: String
        let total: String
        let grandTotal: String
        let materialsProducts: [[String]]
        let servicesProducts: [[String]]
        let diversProducts: [[String]]
        let totalServices: String
        let totalMaterials: String
        let totalDivers: String
        let limitDate: String
        let facturationDate: String
        let delayDays: String
        let totalDelay: String
        let tva: String
        let siret: String
        let hasTva: Bool
        let hasSiret: Bool
        let hasADelay: Bool
        let hasComment: Bool
        let comment: String
        let interestMessage: String
    }
}
