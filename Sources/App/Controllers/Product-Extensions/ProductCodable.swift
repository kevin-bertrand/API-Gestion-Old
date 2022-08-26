//
//  ProductCodable.swift
//  
//
//  Created by Kevin Bertrand on 26/08/2022.
//

import Foundation

extension Product {
    struct Create: Codable {
        let productID: UUID
        let quantity: Double
    }
}
