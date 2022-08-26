//
//  ProductCodable.swift
//  
//
//  Created by Kevin Bertrand on 26/08/2022.
//

import Foundation

extension Product {
    struct CreateEstimate: Codable {
        let productID: UUID
        let quantity: Double
    }
    
    struct UpdateEstimate: Codable {
        let productEstimateID: UUID?
        let productID: UUID
        let quantity: Double
    }
    
    struct Informations: Codable {
        let quantity: Double
        let title: String
        let unity: String?
        let domain: Domain
        let productCategory: ProductCategory
        let price: Double
    }
}