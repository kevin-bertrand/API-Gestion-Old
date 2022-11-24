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
        let gender = try await database.enum(NameManager.Enumeration.gender.rawValue).read()
        let position = try await database.enum(NameManager.Enumeration.position.rawValue).read()
        let permissions = try await database.enum(NameManager.Enumeration.permissions.rawValue).read()
        
        try await database.schema(NameManager.Staff.schema.rawValue)
            .id()
            .field(NameManager.Staff.profilePicture.rawValue.fieldKey, .string)
            .field(NameManager.Staff.firstname.rawValue.fieldKey, .string, .required)
            .field(NameManager.Staff.lastname.rawValue.fieldKey, .string, .required)
            .field(NameManager.Staff.phone.rawValue.fieldKey, .string, .required)
            .field(NameManager.Staff.email.rawValue.fieldKey, .string, .required)
            .field(NameManager.Staff.gender.rawValue.fieldKey, gender, .required)
            .field(NameManager.Staff.position.rawValue.fieldKey, position, .required)
            .field(NameManager.Staff.role.rawValue.fieldKey, .string, .required)
            .field(NameManager.Staff.passwordHash.rawValue.fieldKey, .string, .required)
            .field(NameManager.Staff.permissions.rawValue.fieldKey, permissions, .required)
            .field(NameManager.Staff.addressId.rawValue.fieldKey, .uuid, .required, .references(Address.schema, "id"))
            .unique(on: NameManager.Staff.email.rawValue.fieldKey)
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(NameManager.Staff.schema.rawValue).delete()
    }
}

