//
//  UserTokenMigration.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

struct UserTokenMigration: AsyncMigration {
    // Create DB
    func prepare(on database: Database) async throws {
        try await database.schema(UserToken.schema)
            .id()
            .field("creation", .datetime, .required)
            .field("value", .string, .required)
            .field("staff_id", .uuid, .required, .references(Staff.schema, "id", onDelete: .cascade))
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(UserToken.schema).delete()
    }
}

