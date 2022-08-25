//
//  StaffMigration.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

struct StaffMigration: AsyncMigration {
    // Create DB
    func prepare(on database: Database) async throws {
        let gender = try await database.enum("gender").read()
        let position = try await database.enum("position").read()
        
        try await database.schema(Staff.schema)
            .id()
            .field("firstname", .string, .required)
            .field("lastname", .string, .required)
            .field("phone", .string, .required)
            .field("email", .string, .required)
            .field("gender", gender, .required)
            .field("position", position, .required)
            .field("role", .string, .required)
            .field("password_hash", .string, .required)
            .field("address_id", .uuid, .required, .references(Address.schema, "id"))
            .unique(on: "email")
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(Staff.schema).delete()
    }
}

