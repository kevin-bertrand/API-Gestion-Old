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
        try await database.schema(NameManager.PaymentMethod.schema.rawValue)
            .id()
            .field(NameManager.PaymentMethod.title.rawValue.fieldKey, .string, .required)
            .field(NameManager.PaymentMethod.iban.rawValue.fieldKey, .string, .required)
            .field(NameManager.PaymentMethod.bic.rawValue.fieldKey, .string, .required)
            .unique(on: NameManager.PaymentMethod.iban.rawValue.fieldKey)
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(NameManager.PaymentMethod.schema.rawValue).delete()
    }
}

