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
    @Field(key: "quantity")
    var quantity: Double
    
    @Field(key: "reduction")
    var reduction: Double
    
    @Parent(key: "product_id")
    var product: Product
    
    @Parent(key: "invoice_id")
    var invoice: Invoice
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil, quantity: Double, reduction: Double = 0.0, productID: UUID, invoiceID: UUID) throws {
        self.id = id
        self.quantity = quantity
        self.reduction = reduction
        self.$product.id = productID
        self.$invoice.id = invoiceID
    }
}
