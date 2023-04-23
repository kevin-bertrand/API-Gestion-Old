//
//  DeviceMigration.swift
//  
//
//  Created by Kevin Bertrand on 05/12/2022.
//

import Fluent
import Vapor

struct DeviceMigration: AsyncMigration {
    // Create DB
    func prepare(on database: Database) async throws {
        try await database.schema(NameManager.Device.schema.rawValue)
            .id()
            .field(NameManager.Device.deviceId.rawValue.fieldKey, .string, .required)
            .field(NameManager.Device.staffId.rawValue.fieldKey, .uuid, .required, .references(NameManager.Staff.schema.rawValue, "id"))
            .create()
    }
    
    // Delete DB
    func revert(on database: Database) async throws {
        try await database.schema(NameManager.Device.schema.rawValue).delete()
    }
}
