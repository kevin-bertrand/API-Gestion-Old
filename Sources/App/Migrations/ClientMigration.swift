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
        let personType = try await database.enum(NameManager.Enumeration.personType.rawValue).read()
        let gender = try await database.enum(NameManager.Enumeration.gender.rawValue).read()
        
        try await database.schema(NameManager.Client.schema.rawValue)
            .id()
            .field(NameManager.Client.firstname.rawValue.fieldKey, .string)
            .field(NameManager.Client.lastname.rawValue.fieldKey, .string)
            .field(NameManager.Client.company.rawValue.fieldKey, .string)
            .field(NameManager.Client.phone.rawValue.fieldKey, .string, .required)
            .field(NameManager.Client.email.rawValue.fieldKey, .string, .required)
            .field(NameManager.Client.personType.rawValue.fieldKey, personType, .required)
            .field(NameManager.Client.gender.rawValue.fieldKey, gender, .required)
            .field(NameManager.Client.siret.rawValue.fieldKey, .string)
            .field(NameManager.Client.tva.rawValue.fieldKey, .string)
            .field(NameManager.Client.addressId.rawValue.fieldKey, .uuid, .required, .references(Address.schema, "id"))
            .create()
    }
    
    // Deleted DB
    func revert(on database: Database) async throws {
        try await database.schema(NameManager.Client.schema.rawValue).delete()
    }
}

