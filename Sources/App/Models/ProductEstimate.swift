//
//  ProductEstimate.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

final class ProductEstimate: Model, Content {
    // Name of the table
    static let schema: String = NameManager.ProductEstimate.schema.rawValue
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @Field(key: NameManager.ProductEstimate.quantity.rawValue.fieldKey)
    var quantity: Double
    
    @Field(key: NameManager.ProductEstimate.reduction.rawValue.fieldKey)
    var reduction: Double
    
    @Parent(key: NameManager.ProductEstimate.productId.rawValue.fieldKey)
    var product: Product
    
    @Parent(key: NameManager.ProductEstimate.estimateId.rawValue.fieldKey)
    var estimate: Estimate
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil, quantity: Double, reduction: Double = 0.0, productID: UUID, estimateID: UUID) throws {
        self.id = id
        self.quantity = quantity
        self.reduction = reduction
        self.$product.id = productID
        self.$estimate.id = estimateID
    }
}
