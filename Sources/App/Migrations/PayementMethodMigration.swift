//
//  PayementMethodMigration.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

struct PayementMethodMigration: AsyncMigration {
    // Create DB
    func prepare(on database: Database) async throws {
        try await database.schema(PayementMethod.schema)
            .id()
            .field("title", .string, .required)
            .field("iban", .string, .required)
            .field("bic", .string, .required)
            .unique(on: "iban")
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(PayementMethod.schema).delete()
    }
}

