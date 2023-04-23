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
    static let schema: String = NameManager.ProductInvoice.schema.rawValue
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @Field(key: NameManager.ProductInvoice.quantity.rawValue.fieldKey)
    var quantity: Double
    
    @Field(key: NameManager.ProductInvoice.reduction.rawValue.fieldKey)
    var reduction: Double
    
    @Parent(key: NameManager.ProductInvoice.productId.rawValue.fieldKey)
    var product: Product
    
    @Parent(key: NameManager.ProductInvoice.invoiceId.rawValue.fieldKey)
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
