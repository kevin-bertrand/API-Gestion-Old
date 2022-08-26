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
        let totalServices: Double
        let totalMaterials: Double
        let total: Double
        let reduction: Double
        let grandTotal: Double
        let status: EstimateStatus
        let limitValidifyDate: Date?
        let clientID: UUID
        let products: [Product.Create]
    }
}
