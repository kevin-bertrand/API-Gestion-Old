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
        try await database.schema(ProductEstimate.schema)
            .id()
            .field("quantity", .double, .required)
            .field("reduction", .double, .required)
            .field("product_id", .uuid, .required, .references(Product.schema, "id"))
            .field("estimate_id", .uuid, .required, .references(Estimate.schema, "id"))
            .create()
        
        try await database.schema(ProductInvoice.schema)
            .id()
            .field("quantity", .double, .required)
            .field("reduction", .double, .required)
            .field("product_id", .uuid, .required, .references(Product.schema, "id"))
            .field("invoice_id", .uuid, .required, .references(Invoice.schema, "id"))
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(ProductEstimate.schema).delete()
        try await database.schema(ProductInvoice.schema).delete()
    }
}

