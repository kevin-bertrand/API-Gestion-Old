//
//  ClientMigration.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

struct ClientMigration: AsyncMigration {
    // Create DB
    func prepare(on database: Database) async throws {
        let personType = try await database.enum("person_type").read()
        let gender = try await database.enum("gender").read()
        
        try await database.schema(Client.schema)
            .id()
            .field("firstname", .string)
            .field("lastname", .string)
            .field("company", .string)
            .field("phone", .string, .required)
            .field("email", .string, .required)
            .field("person_type", personType, .required)
            .field("gender", gender, .required)
            .field("siret", .string)
            .field("tva", .string)
            .field("address_id", .uuid, .required, .references(Address.schema, "id"))
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(Client.schema).delete()
    }
}

