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
        let productCategory = try await database.enum(NameManager.Enumeration.productCategory.rawValue).read()
        let domain = try await database.enum(NameManager.Enumeration.domain.rawValue).read()
        
        try await database.schema(NameManager.Product.schema.rawValue)
            .id()
            .field(NameManager.Product.productCategory.rawValue.fieldKey, productCategory, .required)
            .field(NameManager.Product.domain.rawValue.fieldKey, domain, .required)
            .field(NameManager.Product.title.rawValue.fieldKey, .string, .required)
            .field(NameManager.Product.unity.rawValue.fieldKey, .string)
            .field(NameManager.Product.price.rawValue.fieldKey, .double, .required)
            .unique(on: NameManager.Product.title.rawValue.fieldKey)
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(NameManager.Product.schema.rawValue).delete()
    }
}

