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
        try await database.schema(NameManager.InternalReference.schema.rawValue)
            .id()
            .field(NameManager.InternalReference.reference.rawValue.fieldKey, .string, .required)
            .field(NameManager.InternalReference.estimateId.rawValue.fieldKey, .uuid, .references(Estimate.schema, "id"))
            .field(NameManager.InternalReference.invoiceId.rawValue.fieldKey, .uuid, .references(Invoice.schema, "id"))
            .unique(on: NameManager.InternalReference.reference.rawValue.fieldKey)
            .create()
    }
    
    // Delete DB
    func revert(on database: Database) async throws {
        try await database.schema(NameManager.InternalReference.schema.rawValue).delete()
    }
}
