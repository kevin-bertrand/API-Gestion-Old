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
        try await database.schema(Address.schema)
            .id()
            .field("road_name", .string, .required)
            .field("street_number", .string, .required)
            .field("complement", .string)
            .field("zip_code", .string, .required)
            .field("city", .string, .required)
            .field("country", .string, .required)
            .field("latitude", .double, .required)
            .field("longitude", .double, .required)
            .field("comment", .string)
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(Address.schema).delete()
    }
}

