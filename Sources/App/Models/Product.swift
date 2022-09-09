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
    static let schema: String = "product"
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @Enum(key: "product_category")
    var productCategory: ProductCategory
    
    @Enum(key: "domain")
    var domain: Domain
    
    @Field(key: "title")
    var title: String
    
    @OptionalField(key: "unity")
    var unity: String?
    
    @Field(key: "price")
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
