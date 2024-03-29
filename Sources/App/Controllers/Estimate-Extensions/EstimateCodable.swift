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
        let status: EstimateStatus
        let limitValidifyDate: Date?
        let sendingDate: Date
        let creationDate: Date?
        let products: [Product.Update]
    }
    
    struct Summary: Codable {
        let id: UUID?
        let client: Client.Summary
        let reference: String
        let total: Double
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
        let status: EstimateStatus
        let limitValidityDate: Date
        let creationDate: Date?
        let sendingDate: Date
        let isArchive: Bool
        let client: Client.Informations
        let products: [Product.Informations]
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
        let total: String
        let materialsProducts: [[String]]
        let servicesProducts: [[String]]
        let diversProducts: [[String]]
        let totalServices: String
        let totalMaterials: String
        let totalDivers: String
        let limitDate: String
        let sendingDate: String
        let tva: String
        let siret: String
        let hasTva: Bool
        let hasSiret: Bool
    }
    
    struct Getting: Codable {
        let startDate: String?
        let endDate: String?
    }
}
