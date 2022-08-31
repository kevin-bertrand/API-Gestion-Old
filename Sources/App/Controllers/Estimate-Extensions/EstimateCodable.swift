//
//  EstimateCodable.swift
//  
//
//  Created by Kevin Bertrand on 26/08/2022.
//

import Foundation

extension Estimate {
    struct Create: Codable {
        let reference: String
        let internalReference: String
        let object: String
        let totalServices: Double
        let totalMaterials: Double
        let totalDivers: Double
        let total: Double
        let reduction: Double
        let grandTotal: Double
        let status: EstimateStatus
        let limitValidifyDate: Date?
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
        let totalDivers: Double
        let total: Double
        let reduction: Double
        let grandTotal: Double
        let status: EstimateStatus
        let limitValidifyDate: Date?
        let products: [Product.Update]
    }
    
    struct Summary: Codable {
        let id: UUID?
        let client: Client.Summary
        let reference: String
        let grandTotal: Double
        let status: EstimateStatus
        let limitValidifyDate: Date
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
        let reduction: Double
        let grandTotal: Double
        let status: EstimateStatus
        let limitValidityDate: Date
        let isArchive: Bool
        let client: Client.Informations
        let products: [Product.Informations]
    }
}
