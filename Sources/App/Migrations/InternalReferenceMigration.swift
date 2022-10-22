//
//  InternalReferenceMigration.swift
//  
//
//  Created by Kevin Bertrand on 22/10/2022.
//

import Fluent
import Vapor

struct InternalReferenceMigration: AsyncMigration {
    // Create DB
    func prepare(on database: Database) async throws {
        try await database.schema(InternalReference.schema)
            .id()
            .field("ref", .string, .required)
            .field("estimate_id", .uuid, .references(Estimate.schema, "id"))
            .field("invoice_id", .uuid, .references(Invoice.schema, "id"))
            .unique(on: "ref")
            .create()
    }
    
    // Delete DB
    func revert(on database: Database) async throws {
        try await database.schema(InternalReference.schema).delete()
    }
}
