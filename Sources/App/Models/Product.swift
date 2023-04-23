//
//  Product.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

final class Product: Model, Content, Codable {
    // Name of the table
    static let schema: String = NameManager.Product.schema.rawValue
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @Enum(key: NameManager.Product.productCategory.rawValue.fieldKey)
    var productCategory: ProductCategory
    
    @Enum(key: NameManager.Product.domain.rawValue.fieldKey)
    var domain: Domain
    
    @Field(key: NameManager.Product.title.rawValue.fieldKey)
    var title: String
    
    @OptionalField(key: NameManager.Product.unity.rawValue.fieldKey)
    var unity: String?
    
    @Field(key: NameManager.Product.price.rawValue.fieldKey)
    var price: Double
    
    @Siblings(through: ProductInvoice.self, from: \.$product, to: \.$invoice)
    public var invoices: [Invoice]
    
    @Siblings(through: ProductEstimate.self, from: \.$product, to: \.$estimate)
    public var estimates: [Estimate]
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil,
         productCategory: ProductCategory,
         domain: Domain,
         title: String,
         unity: String? = nil,
         price: Double) {
        self.id = id
        self.productCategory = productCategory
        self.domain = domain
        self.title = title
        self.unity = unity
        self.price = price
    }
}
