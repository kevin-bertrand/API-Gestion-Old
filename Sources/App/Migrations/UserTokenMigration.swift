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
        try await database.schema(NameManager.UserToken.schema.rawValue)
            .id()
            .field(NameManager.UserToken.creation.rawValue.fieldKey, .datetime, .required)
            .field(NameManager.UserToken.value.rawValue.fieldKey, .string, .required)
            .field(NameManager.UserToken.staffId.rawValue.fieldKey, .uuid, .required, .references(Staff.schema, "id", onDelete: .cascade))
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(NameManager.UserToken.schema.rawValue).delete()
    }
}

