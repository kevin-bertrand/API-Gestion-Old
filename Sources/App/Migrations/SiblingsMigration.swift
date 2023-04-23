//
//  SiblingsMigration.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

struct SiblingsMigration: AsyncMigration {
    // Create DB
    func prepare(on database: Database) async throws {
        try await database.schema(NameManager.ProductEstimate.schema.rawValue)
            .id()
            .field(NameManager.ProductEstimate.quantity.rawValue.fieldKey, .double, .required)
            .field(NameManager.ProductEstimate.reduction.rawValue.fieldKey, .double, .required)
            .field(NameManager.ProductEstimate.productId.rawValue.fieldKey, .uuid, .required, .references(Product.schema, "id"))
            .field(NameManager.ProductEstimate.estimateId.rawValue.fieldKey, .uuid, .required, .references(Estimate.schema, "id"))
            .create()
        
        try await database.schema(NameManager.ProductInvoice.schema.rawValue)
            .id()
            .field(NameManager.ProductInvoice.quantity.rawValue.fieldKey, .double, .required)
            .field(NameManager.ProductInvoice.reduction.rawValue.fieldKey, .double, .required)
            .field(NameManager.ProductInvoice.productId.rawValue.fieldKey, .uuid, .required, .references(Product.schema, "id"))
            .field(NameManager.ProductInvoice.invoiceId.rawValue.fieldKey, .uuid, .required, .references(Invoice.schema, "id"))
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(NameManager.ProductEstimate.schema.rawValue).delete()
        try await database.schema(NameManager.ProductInvoice.schema.rawValue).delete()
    }
}

