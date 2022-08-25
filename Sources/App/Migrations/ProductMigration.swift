//
//  ProductMigration.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

struct ProductMigration: AsyncMigration {
    // Create DB
    func prepare(on database: Database) async throws {
        let productCategory = try await database.enum("product_category").read()
        let domain = try await database.enum("domain").read()
        
        try await database.schema(Product.schema)
            .id()
            .field("product_category", productCategory, .required)
            .field("domain", domain, .required)
            .field("title", .string, .required)
            .field("unity", .string)
            .field("price", .double, .required)
            .unique(on: "title")
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(Product.schema).delete()
    }
}

