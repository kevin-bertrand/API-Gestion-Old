//
//  AddressMigration.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

struct AddressMigration: AsyncMigration {
    // Create DB
    func prepare(on database: Database) async throws {
        try await database.schema(NameManager.Address.schema.rawValue)
            .id()
            .field(NameManager.Address.roadName.rawValue.fieldKey, .string, .required)
            .field(NameManager.Address.streetNumber.rawValue.fieldKey, .string, .required)
            .field(NameManager.Address.complement.rawValue.fieldKey, .string)
            .field(NameManager.Address.zipCode.rawValue.fieldKey, .string, .required)
            .field(NameManager.Address.city.rawValue.fieldKey, .string, .required)
            .field(NameManager.Address.country.rawValue.fieldKey, .string, .required)
            .field(NameManager.Address.latitude.rawValue.fieldKey, .double, .required)
            .field(NameManager.Address.longitude.rawValue.fieldKey, .double, .required)
            .field(NameManager.Address.comment.rawValue.fieldKey, .string)
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(NameManager.Address.schema.rawValue).delete()
    }
}

