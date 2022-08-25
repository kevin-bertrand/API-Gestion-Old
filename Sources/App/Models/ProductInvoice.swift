//
//  ProductInvoice.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

final class ProductInvoice: Model, Content {
    // Name of the table
    static let schema: String = "product_invoice"
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @Parent(key: "product_id")
    var product: Product
    
    @Parent(key: "invoice_id")
    var invoice: Invoice
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil, product: Product, invoice: Invoice) throws {
        self.id = id
        self.$product.id = try product.requireID()
        self.$invoice.id = try invoice.requireID()
    }
}
